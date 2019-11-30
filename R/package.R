#' @title AmoCRM API client for R
#'
#' @description
#' A package for extracting data from AmoCRM into R.
#'
#' @section Key features:
#'
#' \itemize{
#'  \item Package usage instructions and documentation \href{https://github.com/grkhr/amocrm}{here};
#'  \item AmoCRM API official documentation \href{https://www.amocrm.ru/developers/content/api/account}{here};
#' }
#'
#' To report a bug please type \href{https://github.com/grkhr/amocrm/issues}{do an issue}.
#'
#' @section Usage:
#'
#' As simple as:
#'
#' \enumerate{
#'   \item Do auth_list with \code{\link{AmoAuthList}} function;
#'   \item Load the data e.g. \code{\link{AmoUsers}} function.
#' }
#'
#' @name amocrm-package
#' @docType package
#' @keywords package
#' @aliases amocrm AMOCRM AmoCRM
#'
#' @author Eduard Gorkh \email{eduardgorkh@@gmail.com}
#'
#' @examples
#' \dontrun{
#' # load package
#' library(amocrm)
#'
#' # do auth list
#' auth_list <- AmoAuthList(email = "test@@test.ru", apikey = "test", domain = "test")
#'
#' # get users
#' users <- AmoUsers(auth_list = auth_list)
#'
#' # get leads
#' leads <- AmoLeads(auth_list = auth_list)
#' }
#'
NULL
