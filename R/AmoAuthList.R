#' Auth list
#'
#' Using for nice-passing auth parameters
#'
#' @param email Your email in AmoCRM, check xxx.amocrm.ru/settings/profile/
#' @param apikey Your api key from settings in interface, check xxx.amocrm.ru/settings/profile/
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @return List of auth parameters
#' @export
#' @examples
#' AmoAuthList("email@email.ru", "shdfuisgea3624dwe6t", "test")

AmoAuthList <- function(email = NULL, apikey = NULL, domain = NULL) {
  auth_list <- list(email = email,
                    apikey = apikey,
                    domain = domain)
  return(auth_list)
}
