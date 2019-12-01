#' Tasks
#'
#' Function to get tasks.
#'
#' @param email Email
#' @param apikey Your api key from settings in interface
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @param auth_list List with auth data, you can build from AmoAuthList
#' @param limit Batch limit, sometimes AmoCRM's API doesn't work properly, you can reduce the value and have a chance to load your data
#' @param id Filter. Pass id or vector of ids of tasks.
#' @param type Filter. Works if element_id is set. Pass \code{"lead"}, \code{"contact"}, \code{"company"} or \code{"customer"}.
#' @param element_id Filter. Pass contact/lead/etc id.
#' @param responsible_user_id Filter. Pass id or vector of ids of responsible user ids. You can get ids from AmoUsers().
#' @param date_create_from Filter. Date create of taks. You can pass like \code{'2019-01-01'} or like \code{'2019-01-01 12:30:00'}.
#' @param date_create_to Filter. Date create of taks. You can pass like \code{'2019-01-01'} or like \code{'2019-01-01 12:30:00'}.
#' @param date_modify_from Filter. Date modify of taks. You can pass like \code{'2019-01-01'} or like \code{'2019-01-01 12:30:00'}.
#' @param date_modify_to Filter. Date modify of taks. You can pass like \code{'2019-01-01'} or like \code{'2019-01-01 12:30:00'}.
#' @param status Filter. Pass \code{1} if you need done tasks, pass \code{0} if undone tasks.
#' @param created_by Filter. Tasks by author. Pass if of user or vector of ids.
#' @param task_type Filter. Task by its type. Pass id. You can get id from AmoTaskTypes(). \href{https://www.amocrm.ru/developers/content/api/tasks#type}{More}.
#' @export
#' @importFrom httr GET
#' @importFrom httr content
#' @importFrom plyr mapvalues
#' @include query_functions.R
#' @include unnest_functions.R
#' @import dplyr
#' @import tictoc
#' @return Dataframe in output.
#'
#' @references
#' Please \strong{READ} this:
#' \href{https://github.com/grkhr/amocrm/blob/master/md/AmoTasks.md}{Function documentation in Russian on GitHub}
#'
#' Also nice to read:
#' \href{https://www.amocrm.ru/developers/content/api/tasks}{AmoCRM official documentation}
#'
#' @examples
#' # simple
#' tasks <- AmoTasks(auth_list = auth_list)
#'
#' # filters
#' tasks <- AmoTasks(auth_list = auth_list,
#'                   type = 'lead',
#'                   date_create_from = '2019-02-01 05:00:00',
#'                   date_create_to = '2019-02-20 17:00:00',
#'                   status = 0,
#'                   task_type = 1)
#'
AmoTasks <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL, limit = 500,
                     id = NULL, type = NULL, element_id = NULL, responsible_user_id = NULL,
                     date_create_from = NULL, date_create_to = NULL, date_modify_from = NULL, date_modify_to = NULL,
                     status = NULL, created_by = NULL, task_type = NULL) {
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

  packageStartupMessage('Processing tasks...')
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

  tasks_all = data.frame()

  # main
  while (limit_limit == limit) {

    # auth if too long
    if (limit_offset %% (auth_limit - auth_limit %% limit) == 0) {
      auth <- AmoAuth(email, apikey, domain, verbose=F)
      if (auth != T) stop(auth)
    }

    # query params
    que_easy <- list( limit_rows = limit_rows,
                      limit_offset = limit_offset,
                      id = pasteNULL(id),
                      element_id = pasteNULL(element_id),
                      type = pasteNULL(type),
                      "filter[date_create][from]" = if(is.null(date_create_from)) NULL else as.POSIXct(date_create_from, tz = 'UTC'),
                      "filter[date_create][to]" = if(is.null(date_create_to)) NULL else as.POSIXct(date_create_to, tz = 'UTC'),
                      "filter[date_modify][from]" = if(is.null(date_modify_from)) NULL else as.POSIXct(date_modify_from, tz = 'UTC'),
                      "filter[date_modify][to]" = if(is.null(date_modify_to)) NULL else as.POSIXct(date_modify_to, tz = 'UTC'),
                      "filter[status]" = status)

    que_array <- list("responsible_user_id[]" = responsible_user_id,
                      "filter[created_by][]" = created_by,
                      "filter[task_type][]" = task_type)
    que <- build_full_query(que_easy, que_array)

    answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/tasks"), query=que)
    dataRaw <- content(answer, "parsed", "application/json")

    tasks <- dataRaw$`_embedded`$items
    last_limit <- limit_offset
    limit_limit <- length(tasks)
    # amo bug
    if (length(tasks) == 0) {
      answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/tasks"), query=que)
      dataRaw <- content(answer, "parsed", "application/json")
      tasks <- dataRaw$`_embedded`$items
      limit_limit <- length(tasks)
    }
    limit_offset <- limit_offset + limit_limit
    if (last_limit == limit_offset & last_limit != 0) stop("Seems that AmoCRM API doesn't work properly.
                                                           Try another limit parameter, wait some time or contact Amo technical support.")

    tasks_df <- lapply(tasks, function(x) {
      # delete
      if (!is.null(x$`_links`)) x$`_links` <- NULL
      if (!is.null(x$`_embedded`)) x$`_embedded` <- NULL

      # unlist
      if (!is.null(x$result)) {
        x$result_id <- x$result$id
        x$result_text <- x$result$text
        x$result <- NULL
      }

      x

    }) %>% bind_rows()

    # dataframes
    tasks_all <- bind_rows(tasks_all, tasks_df)

    packageStartupMessage("Tasks processed: ", limit_offset)
  }

  # warning
  options(warn = 0)
  if (nrow(tasks_all) == 0) warning("Oops... seems that you've requested zero rows")

  if (nrow(tasks_all)) {
    tasks_all <- get_datetime(tasks_all, c('complete_till_at', 'created_at', 'updated_at'), email, apikey, domain) %>%
      mutate(element_type = mapvalues(element_type,
                                      c(1, 2, 3, 12),
                                      c('contact', 'lead', 'company', 'customer'),
                                      warn_missing = F))
  }

  # main
  main_list <- tasks_all

  packageStartupMessage("_____________________")
  s <- toc(quiet = T)
  packageStartupMessage("Done. Elapsed ", as.numeric(round(s$toc - s$tic)), " seconds.")
  return(main_list)
}

