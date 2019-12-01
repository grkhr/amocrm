#' Leads
#'
#' Function to get leads.
#'
#' @param email Email
#' @param apikey Your api key from settings in interface
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @param auth_list List with auth data, you can build from AmoAuthList
#' @param limit Batch limit, sometimes AmoCRM's API doesn't work properly, you can reduce the value and have a chance to load your data
#' @param flatten Set \code{TRUE} if you want to join all the output dataframes You'll have a not tidy-dataframe with left-joining all dataframes
#' @param id Filter. Pass id or vector of ids of leads.
#' @param query Filter. Searching for all fields of leads. String.
#' @param responsible_user_id Filter. Pass id or vector of ids of responsible user ids. You can get ids from AmoUsers().
#' @param with_with Additional data. Default to \code{'is_price_modified_by_robot,loss_reason_name'}.
#' @param status Filter. Single status id or vector of ids. You can get ids from AmoPipelinesStatuses().
#' @param date_create_from Filter. Date create of lead. You can pass like \code{'2019-01-01'} or like \code{'2019-01-01 12:30:00'}.
#' @param date_create_to Filter. Date create of lead. You can pass like \code{'2019-01-01'} or like \code{'2019-01-01 12:30:00'}.
#' @param date_modify_from Filter. Date modify of lead. You can pass like \code{'2019-01-01'} or like \code{'2019-01-01 12:30:00'}.
#' @param date_modify_to Filter. Date modify of lead. You can pass like \code{'2019-01-01'} or timezone like \code{'2019-01-01 12:30:00'}.
#' @param tasks Filter. Pass \code{1} if you need leads without tasks, pass \code{2} if you need leads with undone tasks.
#' @param active Filter. Pass \code{1} if you need only active leads.
#' @export
#' @importFrom httr GET
#' @importFrom httr content
#' @include query_functions.R
#' @include unnest_functions.R
#' @import dplyr
#' @import tictoc
#' @return If flatten is \code{FALSE} (default) you'll get a list of 4 tidy-dataframes which you can join by id. You can access it using list_name$dataframe_name.
#'
#' leads - all leads with unnested parameters.
#'
#' linked_custom_fields — linked custom fields with all parameters.
#'
#' linked_tags — linked tags with all parameters.
#'
#' linked_contacts — linked contacts with all parameters.
#'
#' @references
#' Please \strong{READ} this:
#' \href{https://github.com/grkhr/amocrm/blob/master/md/AmoLeads.md}{Function documentation in Russian on GitHub}
#'
#' Also nice to read:
#' \href{https://www.amocrm.ru/developers/content/api/leads}{AmoCRM official documentation}
#'
#' @examples
#' # simple
#' library(dplyr)
#' leads <- AmoLeads(auth_list = auth_list)
#' leads_with_cf <- leads$leads %>%
#'                         left_join(leads$linked_custom_fields, by = 'id') # not tidy
#'
#' # filters
#' leads <- AmoLeads(auth_list = auth_list,
#'                   date_create_from = '2019-02-01 05:00:00',
#'                   date_create_to = '2019-02-20 17:00:00',
#'                   active = 1)
#'
AmoLeads <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL, limit = 500, flatten = F,
                     id = NULL, query = NULL, responsible_user_id = NULL,
                     with_with = 'is_price_modified_by_robot,loss_reason_name', status = NULL,
                     date_create_from = NULL, date_create_to = NULL, date_modify_from = NULL, date_modify_to = NULL,
                     tasks = NULL, active = NULL, timezone = 3) {
  # auth
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  auth <- AmoAuth(email, apikey, domain, verbose=F)
  if (auth != T) stop(auth)

  tz <- get_timezone(email, apikey, domain)
  Sys.setenv(TZ=tz)

  packageStartupMessage('Processing leads...')
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
  auth_limit = limit * 20

  leads_all = data.frame()
  linked_custom_fields_all = data.frame()
  linked_tags_all = data.frame()
  linked_contacts_all = data.frame()

  # main
  while (limit_limit == limit) {

    # auth if too long
    if (limit_offset %% (auth_limit - auth_limit %% limit) == 0) {
      auth <- AmoAuth(email, apikey, domain, verbose = F)
      if (auth != T) stop(auth)
    }

    # query params
    que_easy <- list(limit_rows = limit_rows,
                     limit_offset = limit_offset,
                     id = pasteNULL(id),
                     query = query,
                     "with" = with_with,
                     "filter[date_create][from]" = if(is.null(date_create_from)) NULL else as.POSIXct(date_create_from, tz = 'UTC'),
                     "filter[date_create][to]" = if(is.null(date_create_to)) NULL else as.POSIXct(date_create_to, tz = 'UTC'),
                     "filter[date_modify][from]" = if(is.null(date_modify_from)) NULL else as.POSIXct(date_modify_from, tz = 'UTC'),
                     "filter[date_modify][to]" = if(is.null(date_modify_to)) NULL else as.POSIXct(date_modify_to, tz = 'UTC'),
                     "filter[tasks]" = tasks,
                     "filter[active]" = active
    )
    que_array <- list("responsible_user_id[]" = responsible_user_id,
                      "status[]" = status)
    que <- build_full_query(que_easy, que_array)

    answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/leads"), query = que)
    dataRaw <- content(answer, "parsed", "application/json")

    leads <- dataRaw$`_embedded`$items
    last_limit <- limit_offset
    limit_limit <- length(leads)
    # amo bug
    if (length(leads) == 0) {
      answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/leads"), query=que)
      dataRaw <- content(answer, "parsed", "application/json")
      leads <- dataRaw$`_embedded`$items
      limit_limit <- length(leads)
    }
    limit_offset <- limit_offset + limit_limit
    if (last_limit == limit_offset & last_limit != 0) stop("Seems that AmoCRM API doesn't work properly.
                                         Try another limit parameter, wait some time or contact Amo technical support.")

    leads_df <- lapply(leads, function(x) {
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
    cf_df <- unnestCustomFields(leads)

    # contact ids df
    contacts_df <- unnestContacts(leads)

    # tags ids df
    tags_df <- unnestTags(leads)

    # dataframes
    leads_all <- bind_rows(leads_all, leads_df)
    linked_custom_fields_all <-  bind_rows(linked_custom_fields_all, cf_df)
    linked_tags_all <- bind_rows(linked_tags_all, tags_df)
    linked_contacts_all <- bind_rows(linked_contacts_all, contacts_df)

    packageStartupMessage("Leads processed: ", limit_offset)
  }

  if (nrow(linked_custom_fields_all)) {
    cols <- names(linked_custom_fields_all)
    cols_names <- data.frame(col = c('id', 'cf_id', 'cf_name', 'cf_is_system', 'enum', 'value', 'subtype'),
                             name = c("id", "custom_field_id", "custom_field_name",
                                      "custom_field_is_system","custom_field_value_id","custom_field_value", "custom_field_value_subtype"))
    cols <- cols[grepl('^id$|^cf_id$|^cf_name$|^cf_is_system$|^enum$|^value$|^subtype$',cols)]
    cols_names <- cols_names[cols_names$col %in% cols,]

    linked_custom_fields_all <- linked_custom_fields_all %>%
    select(cols_names$col) %>%
    setNames(cols_names$name)
  }

  if (!is.null(leads_all$closest_task_at)) if (nrow(leads_all[leads_all$closest_task_at <= 0,])) leads_all[leads_all$closest_task_at <= 0,]$closest_task_at <- NA
  if (!is.null(leads_all$closed_at)) if (nrow(leads_all[leads_all$closed_at <= 0,])) leads_all[leads_all$closed_at <= 0,]$closed_at <- NA
  if (nrow(leads_all)) leads_all <- get_datetime(leads_all, c('created_at', 'updated_at', 'closed_at', 'closest_task_at'), email, apikey, domain)

  # warning
  options(warn = 0)
  if (nrow(leads_all) == 0) warning("Oops... seems that you've requested zero rows")

  # main
  if (flatten) {
    main_list <- leads_all
    if (nrow(linked_custom_fields_all)) main_list <-  left_join(main_list, linked_custom_fields_all, by = "id")
    if (nrow(linked_tags_all)) main_list <-  left_join(main_list, linked_tags_all, by = "id")
    if (nrow(linked_contacts_all)) main_list <-  left_join(main_list, linked_contacts_all, by = "id")
  } else {
    main_list <- list()
    main_list$leads <- leads_all
    main_list$linked_custom_fields <- linked_custom_fields_all
    main_list$linked_tags <- linked_tags_all
    main_list$linked_contacts <- linked_contacts_all
  }

  packageStartupMessage("_____________________")
  s <- toc(quiet = T)
  packageStartupMessage("Done. Elapsed ", as.numeric(round(s$toc - s$tic)), " seconds.")
  return(main_list)
}
