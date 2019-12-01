#' Users from account
#'
#' Function to get users.
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
#' @import tictoc
#' @return Dataframe in output.
#'
#' @references
#' Please \strong{READ} this:
#' \href{https://github.com/grkhr/amocrm/blob/master/md/AmoUsers.md}{Function documentation in Russian on GitHub}
#'
#' Also nice to read:
#' \href{https://www.amocrm.ru/developers/content/api/account}{AmoCRM official documentation}
#'
#' @examples
#' users <- AmoUsers(auth_list = auth_list)
#'
AmoUsers <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL) {
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  auth <- AmoAuth(email, apikey, domain, verbose=F)
  if (auth != T) stop(auth)

  answer <- GET(paste0("https://",domain,".amocrm.ru/api/v2/account?with=users"))
  dataRaw <- content(answer, "parsed", "application/json")
  users <- dataRaw$`_embedded`$users

  users_df <- sapply(users, function(x) {
      user_list <- sapply(x, function(y) if (typeof(y) != 'list') y)
      user_list[sapply(user_list, is.null)] <- NULL
      list(user_list)
  }) %>% bind_rows() %>% as.data.frame()

  users_df[users_df == ''] <- NA
  return(users_df)
}
