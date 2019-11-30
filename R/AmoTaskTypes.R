#' Task types from account
#'
#' Function to get tasks. Please read the following manual on github: \code{\link{https://github.com/grkhr/amocrm}}
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
#' task_types <- AmoTaskTypes(auth_list = auth_list)

AmoTaskTypes <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL) {
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  auth <- AmoAuth(email, apikey, domain, verbose=F)
  if (auth != T) stop(auth)

  answer <- GET(paste0("https://",domain,".amocrm.ru/api/v2/account?with=task_types"))
  dataRaw <- content(answer, "parsed", "application/json")
  task_types <- dataRaw$`_embedded`$task_types

  task_types_df <- sapply(task_types, function(x) {
    x$color <- NULL
    x$icon_id <- NULL
    list(x)
    }) %>% bind_rows() %>% as.data.frame()

  return(task_types_df)
}
