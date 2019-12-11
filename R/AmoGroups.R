#' Groups
#'
#' Function to get groups of users.
#'
#' @param email Email
#' @param apikey Your api key from settings in interface
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @param auth_list List with auth data, you can build from AmoAuthList
#' @include query_functions.R
#' @include unnest_functions.R
#' @export
#' @importFrom stats setNames
#' @importFrom httr GET
#' @importFrom httr content
#' @import dplyr
#' @return You'll get a groups.
#'
#' @references
#' Please \strong{READ} this:
#' \href{https://github.com/grkhr/amocrm/blob/master/md/AmoGroups.md}{Function documentation in Russian on GitHub}
#'
#' Also nice to read:
#' \href{https://www.amocrm.ru/developers/content/api/account}{AmoCRM official documentation}
#'
#' @examples
#' \dontrun{
#' groups <- AmoGroups(auth_list = auth_list)
#' }
AmoGroups <- function(email = NULL, apikey = NULL, domain = NULL,  auth_list = NULL) {
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  auth <- AmoAuth(email, apikey, domain, verbose=F)
  if (auth != T) stop(auth)
  answer <- GET(paste0("https://",domain,".amocrm.ru/api/v2/account?with=groups"))
  dataRaw <- content(answer, "parsed", "application/json")
  groups <- dataRaw$`_embedded`$groups

  groups_df <- bind_rows(groups) %>% as.data.frame()
  return(groups_df)
}
