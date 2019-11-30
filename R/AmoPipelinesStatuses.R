#' Pipelines and statuses
#'
#' Function to get pipelines and statuses. Please read the following manual on github: \code{\link{https://github.com/grkhr/amocrm}}
#'
#' Check api params if needed: \code{\link{https://www.amocrm.ru/developers/content/api/account}}
#' @param email Email
#' @param apikey Your api key from settings in interface
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @param auth_list List with auth data, you can build from AmoAuthList
#' @include query_functions.R
#' @include unnest_functions.R
#' @export
#' @importFrom httr GET
#' @importFrom httr content
#' @import dplyr
#' @import tictoc
#' @return Dataframe in output.
#'
#' @examples
#' pipelines <- AmoPipelinesStatuses(auth_list = auth_list)

AmoPipelinesStatuses <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL) {
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  auth <- AmoAuth(email, apikey, domain, verbose=F)
  if (auth != T) stop(auth)

  answer <- GET(paste0("https://",domain,".amocrm.ru/api/v2/account?with=pipelines"))
  dataRaw <- content(answer, "parsed", "application/json")
  pipelines <- dataRaw$`_embedded`$pipelines

  pipelines_list <- sapply(pipelines, function(x) {
    if (!is.null(x$`_links`)) x$`_links` <- NULL
    list(x)
  })

  pipelines_df <- sapply(pipelines_list, function(x) {
    obj <- bind_rows(x$statuses)
    names(obj) <- paste0('status_', names(obj))
    obj$pipeline_id <- x$id
    obj$pipeline_name <- x$name
    obj$pipeline_sort <- x$sort
    obj$pipeline_is_main <- x$is_main
    list(obj)
  }) %>% bind_rows()

  nm <- c(names(pipelines_df)[grepl('pipeline', names(pipelines_df))], names(pipelines_df)[grepl('status', names(pipelines_df))])
  pipelines_df <- pipelines_df %>% select(nm) %>% select(-status_color) %>% as.data.frame()

  return(pipelines_df)
}
