#' Companies
#'
#' Function to get companies. Please read the following manual on github: \code{\link{https://github.com/grkhr/amocrm}}
#'
#' Check api params if needed: \code{\link{https://www.amocrm.ru/developers/content/api/companies}}
#' @param email Email
#' @param apikey Your api key from settings in interface
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @param auth_list List with auth data, you can build from AmoAuthList
#' @param limit Batch limit, sometimes AmoCRM's API doesn't work properly, you can reduce the value and have a chance to load your data
#' @param flatten Set TRUE if you want to join all the output dataframes You'll have a not tidy-dataframe with left-joining all dataframes
#' @param id Filter. Pass id or vector of ids of companies.
#' @param query Filter. Searching for all fields of companies. String.
#' @param responsible_user_id Filter. Pass id or vector of ids of responsible user ids. You can get ids from AmoUsers().
#'
#' @export
#' @importFrom httr GET
#' @importFrom httr content
#' @include query_functions.R
#' @include unnest_functions.R
#' @import dplyr
#' @import tictoc
#' @return If flatten is F (default) you'll get a list of 6 tidy-dataframes which you can join by id. You can access it using list_name$dataframe_name.
#'
#' companies - all companies with unnested parameters.
#'
#' linked_custom_fields — linked custom fields with all parameters.
#'
#' linked_tags — linked tags with all parameters.
#'
#' linked_leads — linked leads with all parameters.
#'
#' linked_contacts — linked contacts with all parameters.
#'
#' linked_customers — linked customers with all parameters.
#' @examples
#' library(dplyr)
#' companies <- AmoCompanies(auth_list = auth_list)
#' companies_with_cf <- companies$companies %>%
#'                         left_join(companies$linked_custom_fields, by = 'id') # not tidy

AmoCompanies <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL, limit = 500, flatten = F,
                        id = NULL, query = NULL, responsible_user_id = NULL) {
  # auth
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  auth <- AmoAuth(email, apikey, domain, verbose=F)
  if (auth != T) stop(auth)

  packageStartupMessage('Processing companies...')
  tic()
  options(warn = -1)
  options(scipen=999)
  options(stringsAsFactors = F)

  # batch limit
  limit_rows = limit
  # first offset
  limit_offset = 0
  # variable limit
  limit_limit = limit
  # max before reauth
  auth_limit = limit * 100

  companies_all = data.frame()
  linked_custom_fields_all = data.frame()
  linked_tags_all = data.frame()
  linked_leads_all = data.frame()
  linked_contacts_all = data.frame()
  linked_customers_all = data.frame()

  # main
  while (limit_limit == limit) {

    # auth if too long
    if (limit_offset %% (auth_limit - auth_limit %% limit) == 0) {
      auth <- AmoAuth(email, apikey, domain, verbose=F)
      if (auth != T) stop(auth)
    }

    # query params
    que_easy <- list(limit_rows = limit_rows,
                     limit_offset = limit_offset,
                     id = pasteNULL(id),
                     query = query
                     )
    que_array <- list("responsible_user_id[]" = responsible_user_id)
    que <- build_full_query(que_easy, que_array)

    answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/companies"), query=que)
    dataRaw <- content(answer, "parsed", "application/json")

    companies <- dataRaw$`_embedded`$items
    last_limit <- limit_offset
    limit_limit <- length(companies)
    # amo bug
    if (length(companies) == 0) {
      answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/companies"), query=que)
      dataRaw <- content(answer, "parsed", "application/json")
      companies <- dataRaw$`_embedded`$items
      limit_limit <- length(companies)
    }
    limit_offset <- limit_offset + limit_limit
    if (last_limit == limit_offset& last_limit != 0) stop("Seems that AmoCRM API doesn't work properly.
                                         Try another limit parameter, wait some time or contact Amo technical support.")

    companies_df <- lapply(companies, function(x) {
      # delete
      if (!is.null(x$`_links`)) x$`_links` <- NULL
      if (!is.null(x$`_embedded`)) x$`_embedded` <- NULL

      # will do separately
      if (!is.null(x$custom_fields)) x$custom_fields <- NULL

      # will do separately
      if (!is.null(x$leads)) x$leads <- NULL

      # will do separately
      if (!is.null(x$contacts)) x$contacts <- NULL

      # will do separately
      if (!is.null(x$customers)) x$customers <- NULL

      # will do separately
      if (!is.null(x$tags)) x$tags <- NULL
      x

    }) %>% bind_rows()
    # custom_fields ids df

    cf_df <- unnestCustomFields(companies)

    # leads ids df
    leads_df <- unnestLeads(companies)

    # contact ids df
    contacts_df <- unnestContacts(companies)

    # customers ids df
    customers_df <- unnestCustomers(companies)

    # tags ids df
    tags_df <- unnestTags(companies)


    companies_all <- bind_rows(companies_all, companies_df)
    linked_custom_fields_all <-  bind_rows(linked_custom_fields_all, cf_df)
    linked_tags_all <- bind_rows(linked_tags_all, tags_df)
    linked_leads_all <- bind_rows(linked_leads_all, leads_df)
    linked_contacts_all <- bind_rows(linked_contacts_all, contacts_df)
    linked_customers_all <- bind_rows(linked_customers_all, customers_df)

    packageStartupMessage("Companies processed: ", limit_offset)
  }

  if (nrow(linked_custom_fields_all)) linked_custom_fields_all <- linked_custom_fields_all %>%
    select(id, cf_id, cf_name, cf_is_system, enum, value, subtype) %>%
    setNames(c("id", "custom_field_id", "custom_field_name",
               "custom_field_is_system","custom_field_value_id","custom_field_value","custom_field_value_subtype"))

  # warning
  options(warn = 0)
  if (nrow(companies_all) == 0) warning("Oops... seems that you've requested zero rows")

  if (!is.null(companies_all$closest_task_at)) if(nrow(companies_all[companies_all$closest_task_at <= 0,])) companies_all[companies_all$closest_task_at <= 0,]$closest_task_at <- NA
  if (nrow(companies_all)) companies_all <- get_datetime(companies_all, c('created_at', 'updated_at', 'closest_task_at'), email, apikey, domain)

  # main
  if (flatten) {
    main_list <- companies_all
    if (nrow(linked_custom_fields_all)) main_list <-  left_join(main_list, linked_custom_fields_all, by = "id")
    if (nrow(linked_tags_all)) main_list <-  left_join(main_list, linked_tags_all, by = "id")
    if (nrow(linked_leads_all)) main_list <-  left_join(main_list, linked_leads_all, by = "id")
    if (nrow(linked_contacts_all)) main_list <-  left_join(main_list, linked_contacts_all, by = "id")
    if (nrow(linked_customers_all)) main_list <-  left_join(main_list, linked_customers_all, by = "id")
  } else {
    main_list <- list()
    main_list$companies <- companies_all
    main_list$linked_custom_fields <- linked_custom_fields_all
    main_list$linked_tags <- linked_tags_all
    main_list$linked_leads <- linked_leads_all
    main_list$linked_contacts <- linked_contacts_all
    main_list$linked_customers <- linked_customers_all
  }

  packageStartupMessage("_____________________")
  s <- toc(quiet = T)
  packageStartupMessage("Done. Elapsed ", as.numeric(round(s$toc - s$tic)), " seconds.")
  return(main_list)
}



