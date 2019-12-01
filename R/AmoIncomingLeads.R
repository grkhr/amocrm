#' Incoming Leads
#'
#' Function to get incoming leads.
#'
#' @param email Email
#' @param apikey Your api key from settings in interface
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @param auth_list List with auth data, you can build from AmoAuthList
#' @param limit Batch limit, sometimes AmoCRM's API doesn't work properly, you can reduce the value and have a chance to load your data
#' @param categories Filter. Categories. Vector or single value of \code{"sip"}, \code{"mail"}, \code{"forms"} or \code{"chats"}.
#' @param order_by_key Filter. Key of ordering. For example \code{"created_at"}.
#' @param order_by_value Filter. \code{"asc"} or \code{"desc"}. Works if \code{order_by_key} is set.
#' @param pipeline_id Filter. You can pass single id and get imcoming leads only from this pipeline. You can get ids from AmoPipelinesStatuses().
#' @include query_functions.R
#' @include unnest_functions.R
#' @export
#' @importFrom stats setNames
#' @importFrom httr GET
#' @importFrom httr content
#' @import dplyr
#' @import tictoc
#' @return Dataframe in output.
#'
#'@references
#' Please \strong{READ} this:
#' \href{https://github.com/grkhr/amocrm/blob/master/md/AmoIncomingLeads.md}{Function documentation in Russian on GitHub}
#'
#' Also nice to read:
#' \href{https://www.amocrm.ru/developers/content/api/unsorted}{AmoCRM official documentation}
#'
#' @examples
#' # get all
#' incleads <- AmoIncomingLeads(auth_list = auth_list)
#'
#' # filtered
#' incleads <- AmoIncomingLeads(auth_list = auth_list,
#'                              categories = c('sip','mail'),
#'                              order_by_key = 'created_at',
#'                              order_by_value = 'desc')
#'
AmoIncomingLeads <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL, limit = 500,
                             categories = NULL, order_by_key = NULL, order_by_value = NULL, pipeline_id = NULL) {
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

  packageStartupMessage('Processing incoming leads...')
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

  inc_leads_all = data.frame()

  # main
  while (limit_limit == limit) {

      # auth if too long
      if ((limit_offset * limit_rows) %% (auth_limit - auth_limit %% limit) == 0) {
        auth <- AmoAuth(email, apikey, domain, verbose=F)
        if (auth != T) stop(auth)
      }
      orderby = paste0("order_by[", order_by_key, "]")
      # query params
      que_easy <- list( page_size = limit_rows,
                        limit_offset = limit_offset,
                        "categories[]" = pasteNULL(categories),
                        orderby = order_by_value,
                        pipeline_id = pipeline_id
      )
      que <- build_query(que_easy)

      answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/incoming_leads"), query=que)
      dataRaw <- content(answer, "parsed", "application/json")

      inc_leads <- dataRaw$`_embedded`$items
      last_limit <- limit_offset * limit
      limit_limit <- length(inc_leads)
      # amo bug
      if (length(inc_leads) == 0) {
        answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/incoming_leads"), query=que)
        dataRaw <- content(answer, "parsed", "application/json")
        inc_leads <- dataRaw$`_embedded`$items
        limit_limit <- length(inc_leads)
      }
      limit_offset <- limit_offset + 1
      if (last_limit == limit_offset * limit & last_limit != 0) stop("Seems that AmoCRM API doesn't work properly.
                                                   Try another limit parameter, wait some time or contact Amo technical support.")

      inc_leads_df <- lapply(inc_leads, function(x) {
        # delete
        if (!is.null(x$`_links`)) x$`_links` <- NULL
        if (!is.null(x$`_embedded`)) x$`_embedded` <- NULL

        # will do separately
        if (!is.null(x$incoming_entities)) x$incoming_entities <- NULL

        bind_rows(unlist(x))

      }) %>% bind_rows()

      # dataframes
      inc_leads_all <- bind_rows(inc_leads_all, inc_leads_df)
      if (nrow(inc_leads_all)) {
        inc_leads_all <- inc_leads_all %>% setNames(gsub(".", "_", names(.), fixed = T))
        cols <- names(inc_leads_all)
        cols <- cols[grepl('send_at$|_date$|^created_at$', cols)]
        inc_leads_all <- get_datetime(inc_leads_all, cols, email, apikey, domain)
      }

      packageStartupMessage("Incoming leads processed: ", nrow(inc_leads_all))
  }

  # warning
  options(warn = 0)
  if (nrow(inc_leads_all) == 0) warning("Oops... seems that you've requested zero rows")

  # main
  main_list <- inc_leads_all

  packageStartupMessage("_____________________")
  s <- toc(quiet = T)
  packageStartupMessage("Done. Elapsed ", as.numeric(round(s$toc - s$tic)), " seconds.")
  return(main_list)
}
