#' Authorization
#'
#' Auth, using in other functions
#' @param email Your email in AmoCRM, check xxx.amocrm.ru/settings/profile/
#' @param apikey Your api key from settings in interface, check xxx.amocrm.ru/settings/profile/
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @param auth_list List with auth data, you can build from AmoAuthList
#' @param verbose Printing the answer
#' @export
#' @importFrom httr POST
#' @importFrom httr content
#' @return TRUE if ok and error if not
#' @examples
#' AmoAuth(auth_list = auth_list)

AmoAuth <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL, verbose = T) {
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  body_list <- list(
      USER_LOGIN = email,
      USER_HASH = apikey
      )
  answer <- POST(paste0("https://", domain, ".amocrm.ru/private/api/auth.php?type=json"),
                 body = body_list)
  dataRaw <- content(answer, "parsed", "application/json")
  if (answer$status_code == 200) {
    if (verbose) packageStartupMessage("Authorization to '", dataRaw$response$accounts[[1]]$name, "' account completed successfully.")
  } else {
    if (verbose) packageStartupMessage("Error code: ", dataRaw$response$error_code, ". ", dataRaw$response$error)
  }
  if (answer$status_code == 200) return(T) else return(paste0("Auth error. Error code: ", dataRaw$response$error_code, ". ", dataRaw$response$error))
}
