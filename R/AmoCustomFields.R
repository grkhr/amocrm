#' Custom fields
#'
#' Function to get custom field names and ids for all. Please read the following manual on github: \code{\link{https://github.com/grkhr/amocrm}}
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
#' @return You'll get a list of list of dataframes which you can join by id.
#'
#' list$custom_fields_xxx$custom_fields - ids and names
#'
#' list$custom_fields_xxx$custom_fields_enum - multiple values
#'
#' @examples
#' library(dplyr)
#' custom_fields <- AmoCustomFields(auth_list = auth_list)
#' custom_fields_contacts_with_enum <- custom_field$custom_fields_contacts$custom_fields %>%
#'   left_join(custom_field$custom_fields_contacts$custom_fields_enum, by = 'id') # not tidy

AmoCustomFields <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL) {
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  auth <- AmoAuth(email, apikey, domain, verbose=F)
  if (auth != T) stop(auth)

  options(warn = -1)

  answer <- GET(paste0("https://",domain,".amocrm.ru/api/v2/account?with=custom_fields"))
  dataRaw <- content(answer, "parsed", "application/json")
  cf <- dataRaw$`_embedded`$custom_fields
  cf_contacts <- cf$contacts
  cf_leads <- cf$leads
  cf_companies <- cf$companies
  cf_customers <- cf$customers

  main_list <- list()

  # contacts
  if (length(cf_contacts)) {
    cf_contacts <- unnestCustomFieldsMain(cf_contacts)
    main_list$custom_fields_contacts$custom_fields <- cf_contacts$custom_fields
    main_list$custom_fields_contacts$custom_fields_enum <- cf_contacts$custom_fields_enum
  }

  # leads
  if (length(cf_leads)) {
    cf_leads <- unnestCustomFieldsMain(cf_leads)
    main_list$custom_fields_leads$custom_fields <- cf_leads$custom_fields
    main_list$custom_fields_leads$custom_fields_enum <- cf_leads$custom_fields_enum
  }

  # companies
  if (length(cf_companies)) {
    cf_companies <- unnestCustomFieldsMain(cf_companies)
    main_list$custom_fields_companies$custom_fields <- cf_companies$custom_fields
    main_list$custom_fields_companies$custom_fields_enum <- cf_companies$custom_fields_enum
  }

  # customers
  if (length(cf_customers)) {
    cf_customers <- unnestCustomFieldsMain(cf_customers)
    main_list$custom_fields_customers$custom_fields <- cf_customers$custom_fields
    main_list$custom_fields_customers$custom_fields_enum <- cf_customers$custom_fields_enum
  }

  return(main_list)
}
