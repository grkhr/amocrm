#' Notes
#'
#' Function to get notes. Please read the following manual on github: \code{\link{https://github.com/grkhr/amocrm}}
#'
#' Check api params if needed: \code{\link{https://www.amocrm.ru/developers/content/api/notes}}
#' @param email Email
#' @param apikey Your api key from settings in interface
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @param auth_list List with auth data, you can build from AmoAuthList
#' @param limit Batch limit, sometimes AmoCRM's API doesn't work properly, you can reduce the value and have a chance to load your data
#' @param id Filter. Pass id or vector of ids of notes.
#' @param type What to get. You can pass \code{"contact"}, \code{"lead"}, \code{"company"} or \code{"task"}. Default to \code{"contact"}. If you need all, look at \code{"all"} parameter.
#' @param element_id Filter. Id of lead/contact/etc.
#' @param note_type Type of note. Check docs: \code{\link{https://www.amocrm.ru/developers/content/api/notes#note_types}}
#' @param if_modified_since Filter. Get notes after some timestamp. Pass time like \code{'2019-01-01 12:30:00'}.
#' @param all If you want to load all note for all types, set TRUE. You'll get list of dataframes.
#' @export
#' @import httr
#' @importFrom plyr mapvalues
#' @include query_functions.R
#' @include unnest_functions.R
#' @import dplyr
#' @import tictoc
#' @return Dataframe in output (or list of dataframes if \code{all = TRUE}.)
#'
#' @references
#' Please \strong{READ} this:
#' \href{https://github.com/grkhr/amocrm/blob/master/md/AmoNotes.md}{Function documentation in Russian on GitHub}
#'
#' Also nice to read:
#' \href{https://www.amocrm.ru/developers/content/api/notes}{AmoCRM official documentation}
#'
#' @examples
#' # leads
#' notes <- AmoNotes(aiuth_list = auth_list, type = 'lead')
#'
AmoNotes <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL, limit = 500,
                     id = NULL, element_id = NULL, type = 'contact', note_type = NULL, if_modified_since = NULL, all = F) {
  tic()
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  options(warn = -1)
  options(scipen = 999)
  options(stringsAsFactors = F)

  if (all) type <- c('contact', 'lead', 'company', 'task')
  main_list <- list()

  for (i in type) {
      # auth
      auth <- AmoAuth(email, apikey, domain, verbose=F)
      if (auth != T) stop(auth)

      tz <- get_timezone(email, apikey, domain)
      Sys.setenv(TZ=tz)

      for_what <- ifelse(i == "company", "companies", paste0(i, "s"))

      packageStartupMessage('Processing notes for ', for_what, '...')

      # batch limit
      limit_rows = limit
      # first offset
      limit_offset = 0
      # variable limit
      limit_limit = limit
      # max before reauth
      auth_limit = limit * 20

      notes_all = data.frame()

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
                            type = i,
                            note_type = note_type
          )
          que <- build_query(que_easy)

          Sys.setlocale("LC_TIME", "C")
          hdr <- if (is.null(if_modified_since)) NULL else c("if-modified-since" = format(as.character(as.POSIXct(if_modified_since, tz = "UTC"), "%a, %d %b %Y %H:%M:%S")))
          answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/notes"),
                        query=que,
                        add_headers(.headers = hdr))
          dataRaw <- content(answer, "parsed", "application/json")
          notes <- dataRaw$`_embedded`$items
          last_limit <- limit_offset
          limit_limit <- length(notes)
          # amo bug
          if (length(notes) == 0) {
            answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/notes"), query=que, add_headers(.headers = hdr))
            dataRaw <- content(answer, "parsed", "application/json")
            notes <- dataRaw$`_embedded`$items
            if (length(notes) == 0) {
              Sys.sleep(0.5)
              answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/notes"), query=que, add_headers(.headers = hdr))
              dataRaw <- content(answer, "parsed", "application/json")
              notes <- dataRaw$`_embedded`$items
              limit_limit <- length(notes)
            }
            limit_limit <- length(notes)
          }
          limit_offset <- limit_offset + limit_limit
          if (last_limit == limit_offset & last_limit != 0) stop("Seems that AmoCRM API doesn't work properly.
                                                                 Try another limit parameter, wait some time or contact Amo technical support.")

          notes_df <- lapply(notes, function(x) {
            # amo bug
            x$id <- as.character(x$id)

            # delete
            if (!is.null(x$`_links`)) x$`_links` <- NULL
            if (!is.null(x$`_embedded`)) x$`_embedded` <- NULL

            bind_rows(unlist(x))

          }) %>% bind_rows()

          # dataframes
          notes_all <- bind_rows(notes_all, notes_df)

          packageStartupMessage("Notes for ", for_what, " processed: ", limit_offset)
      }
      if (nrow(notes_all)) {
        notes_all <- notes_all %>% setNames(gsub(".", "_", names(.), fixed = T)) %>% mutate(id = as.integer(id))
        notes_all <- get_datetime(notes_all, c('created_at', 'updated_at'), email, apikey, domain) %>%
          mutate(element_type = mapvalues(element_type,
                                          c(1, 2, 3, 12),
                                          c('contact', 'lead', 'company', 'customer'),
                                          warn_missing = F))
      }
      main_list[[paste(i, "_notes")]] <- notes_all
      packageStartupMessage()
  }
  # warning
  options(warn = 0)
  if (nrow(main_list[[1]]) == 0) warning("Oops... seems that you've requested zero rows")


  if (!all) main_list <- main_list[[1]]

  packageStartupMessage("_____________________")
  s <- toc(quiet = T)
  packageStartupMessage("Done. Elapsed ", as.numeric(round(s$toc - s$tic)), " seconds.")

  return(main_list)
}
