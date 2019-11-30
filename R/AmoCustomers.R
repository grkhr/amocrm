#' Customers
#'
#' Function to get customers. Please read the following manual on github: \code{\link{https://github.com/grkhr/amocrm}}.
#'
#' Check api params if needed: \code{\link{https://www.amocrm.ru/developers/content/api/customers}}
#' @param email Email
#' @param apikey Your api key from settings in interface
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @param auth_list List with auth data, you can build from AmoAuthList
#' @param limit Batch limit, sometimes AmoCRM's API doesn't work properly, you can reduce the value and have a chance to load your data
#' @param flatten Set TRUE if you want to join all the output dataframes You'll have a not tidy-dataframe with left-joining all dataframes
#' @param id Filter. Pass id or vector of ids of customers.
#' @param query Filter. Searching for all fields of customers. String.
#' @param main_user Filter. Pass id or vector of ids of responsible user ids. You can get ids from AmoUsers().
#' @param date_type Filter. Choose date type which you want to filter ('create' or 'modify')
#' @param date_from Filter. Date from, e.g. '2019-01-01'
#' @param date_to Filter. Date to, e.g. '2019-01-01'
#' @param next_date_from Filter. Date from of next purchasing.
#' @param next_date_from Filter. Date to of next purchasing.
#' @include query_functions.R
#' @include unnest_functions.R
#' @export
#' @importFrom httr GET
#' @importFrom httr content
#' @import dplyr
#' @import tictoc
#' @return If flatten is F (default) you'll get a list of 4 tidy-dataframes which you can join by id. You can access it using list_name$dataframe_name.
#'
#' linked_custom_fields — linked custom fields with all parameters.
#'
#' linked_tags — linked tags with all parameters.
#'
#' linked_contacts — linked contacts with all parameters.
#'
#' @examples
#' library(dplyr)
#' customers <- AmoCustomers(auth_list = auth_list)
#' customers_with_cf <- customers$customers %>%
#'                         left_join(customers$linked_custom_fields, by = 'id') # not tidy

AmoCustomers <- function(email = NULL, apikey = NULL, domain = NULL,  auth_list = NULL, limit = 500, flatten = F,
                         id = NULL, query = NULL, main_user = NULL,
                         date_type = NULL, date_from = NULL, date_to = NULL, next_date_from = NULL, next_date_to = NULL) {
  # auth
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  auth <- AmoAuth(email, apikey, domain, verbose=F)
  if (auth != T) stop(auth)

  packageStartupMessage('Processing customers...')
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

  customers_all = data.frame()
  linked_custom_fields_all = data.frame()
  linked_tags_all = data.frame()
  linked_contacts_all = data.frame()

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
                      query = pasteNULL(query),
                      "filter[date][type]" = pasteNULL(date_type),
                      "filter[date][from]" = if (!is.null(date_from)) format(as.Date(date_from), '%d.%m.%Y') else date_from,
                      "filter[date][to]" = if (!is.null(date_to)) format(as.Date(date_to), '%d.%m.%Y') else date_to,
                      "filter[next_date][from]" = if (!is.null(next_date_from)) format(as.Date(next_date_from), '%d.%m.%Y') else next_date_from,
                      "filter[next_date][to]" = if (!is.null(next_date_to)) format(as.Date(next_date_to), '%d.%m.%Y') else next_date_to
    )
    que_array <- list("filter[main_user][]" = main_user)
    que <- build_full_query(que_easy, que_array)

    answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/customers"), query=que)
    dataRaw <- content(answer, "parsed", "application/json")

    customers <- dataRaw$`_embedded`$items
    last_limit <- limit_offset
    limit_limit <- length(customers)
    # amo bug
    if (length(customers) == 0) {
      answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/customers"), query=que)
      dataRaw <- content(answer, "parsed", "application/json")
      customers <- dataRaw$`_embedded`$items
      limit_limit <- length(customers)
    }
    limit_offset <- limit_offset + limit_limit
    if (last_limit == limit_offset & last_limit != 0) stop("Seems that AmoCRM API doesn't work properly. Try another limit parameter, wait some time or contact Amo technical support.")

    customers_df <- lapply(customers, function(x) {
      # delete
      if (!is.null(x$`_links`)) x$`_links` <- NULL
      if (!is.null(x$`_embedded`)) x$`_embedded` <- NULL

      # will do separately
      if (!is.null(x$custom_fields)) x$custom_fields <- NULL

      # will do separately
      if (!is.null(x$contacts)) x$contacts <- NULL

      # unlist
      if (!is.null(x$main_contact)) x$main_contact <- x$main_contact$id

      # unlist
      if (!is.null(x$company)) {
        x$company_id <- x$company$id
        x$company_name <- x$company$name
        x$company <- NULL
      }

      #unlist
      if (!is.null(x$pipeline)) x$pipeline <- x$pipeline$id

      # will do separately
      if (!is.null(x$tags)) x$tags <- NULL
      x

    }) %>% bind_rows()


    # custom_fields ids df
    cf_df <- unnestCustomFields(customers)

    # contact ids df
    contacts_df <- unnestContacts(customers)

    # tags ids df
    tags_df <- unnestTags(customers)

    # dataframes
    customers_all <- bind_rows(customers_all, customers_df)
    linked_custom_fields_all <-  bind_rows(linked_custom_fields_all, cf_df)
    linked_tags_all <- bind_rows(linked_tags_all, tags_df)
    linked_contacts_all <- bind_rows(linked_contacts_all, contacts_df)

    packageStartupMessage("Customers processed: ", limit_offset)
  }

  if (nrow(linked_custom_fields_all)) linked_custom_fields_all <- linked_custom_fields_all %>%
    select(id, cf_id, cf_name, cf_is_system, enum, value, subtype) %>%
    setNames(c("id", "custom_field_id", "custom_field_name",
               "custom_field_is_system","custom_field_value_id","custom_field_value", "custom_field_value_subtype"))

  # warning
  options(warn = 0)
  if (nrow(customers_all) == 0) warning("Oops... seems that you've requested zero rows")

  if (!is.null(customers_all$closest_task_at)) if(nrow(customers_all[customers_all$closest_task_at <= 0,])) customers_all[customers_all$closest_task_at <= 0,]$closest_task_at <- NA
  if (nrow(customers_all)) customers_all <- get_datetime(customers_all, c('created_at', 'updated_at', 'closest_task_at', 'next_date'), email, apikey, domain)

  # main
  if (flatten) {
    main_list <- customers_all
    if (nrow(linked_custom_fields_all)) main_list <-  left_join(main_list, linked_custom_fields_all, by = "id")
    if (nrow(linked_tags_all)) main_list <-  left_join(main_list, linked_tags_all, by = "id")
    if (nrow(linked_contacts_all)) main_list <-  left_join(main_list, linked_contacts_all, by = "id")
  } else {
    main_list <- list()
    main_list$customers <- customers_all
    main_list$linked_custom_fields <- linked_custom_fields_all
    main_list$linked_tags <- linked_tags_all
    main_list$linked_contacts <- linked_contacts_all
  }

  packageStartupMessage("_____________________")
  s <- toc(quiet = T)
  packageStartupMessage("Done. Elapsed ", as.numeric(round(s$toc - s$tic)), " seconds.")
  return(main_list)
}

