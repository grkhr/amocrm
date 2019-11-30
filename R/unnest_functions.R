#' @importFrom dplyr bind_rows
unnestContacts <- function(ls) {
  contacts_df <- lapply(ls, function(x) {
    # check if empty
    if (is.null(x$contacts)) return()
    if (length(x$contacts) == 0) return()

    contacts <- x$contacts

    # delete links
    contacts$`_links` <- NULL
    id <- x$id

    contacts_list <- data.frame(id = id,
                                contact_id = unlist(contacts),
                                contact_idx = seq(length(contacts$id)))
    contacts_list

  }) %>% bind_rows()
  return(contacts_df)
}

#' @importFrom dplyr bind_rows
unnestCustomers <- function(ls) {
  customers_df <- lapply(ls, function(x) {
    # check if empty
    if (is.null(x$customers)) return()
    if (length(x$customers) == 0) return()

    customers <- x$customers

    # delete links
    customers$`_links` <- NULL
    id <- x$id

    customers_list <- data.frame(id = id,
                                 customer_id = unlist(customers),
                                 customer_idx = seq(length(customers$id)))
    customers_list

  }) %>% bind_rows()
  return(customers_df)
}

#' @importFrom dplyr bind_rows
unnestCustomFields <- function(ls) {
  # custom_fields ids df
  cf_df <- lapply(ls, function(x) {

    # check if empty
    if (is.null(x$custom_fields)) return()
    if (length(x$custom_fields) == 0) return()

    # custom_fields
    cf <- x$custom_fields
    id <- x$id

    cf_df <- lapply(cf, function(z) {
      values <- z$values
      z$values <- NULL
      values_df <- bind_rows(values)
      if (is.null(values_df$subtype)) values_df$subtype <- NA
      values_df$cf_id <- z$id
      values_df$cf_name <- z$name
      values_df$cf_is_system <- z$is_system
      values_df
    }) %>% bind_rows()

    cf_df$id <- id
    cf_df

  }) %>% bind_rows()
  return(cf_df)
}

#' @importFrom dplyr bind_rows
unnestLeads <- function(ls) {
  leads_df <- lapply(ls, function(x) {
    # check if empty
    if (is.null(x$leads)) return()
    if (length(x$leads) == 0) return()

    leads <- x$leads

    # delete links
    leads$`_links` <- NULL
    id <- x$id

    leads_list <- data.frame(id = id,
                             lead_id = unlist(leads),
                             lead_idx = seq(length(leads$id)))
    leads_list

  }) %>% bind_rows()
  return(leads_df)
}

#' @importFrom dplyr bind_rows
unnestTags <- function(ls) {
  # custom_fields ids df
  tags_df <- lapply(ls, function(x) {
    if (is.null(x$tags)) return(data.frame())
    if (length(x$tags) == 0) return(data.frame())

    # cont
    tags <- x$tags

    # delete links
    id <- x$id

    tags_df <- bind_rows(tags) %>% setNames(c("tag_id", "tag_name"))
    tags_list <- cbind(id = id,
                       tags_df,
                       tag_idx = seq(length(tags)))

    tags_list

  }) %>% bind_rows()
  return(tags_df)
}

#' @importFrom dplyr bind_rows
unnestCustomFieldsMain <- function(ls) {
  # fields df
  ls_df <- sapply(ls, function(x) {
    x$params <- NULL
    x$enums <- NULL
    list(x)
  }) %>% bind_rows()
  ls_df[ls_df == ''] <- NA

  # field values / enum
  ls_enum <- sapply(ls, function(x) {
    if (!is.null(x$enums)) {
      obj <- data.frame(id = x$id,
                        name = x$name,
                        enum_id = names(x$enums),
                        enum_name = unlist(x$enums))
      return(obj)
    }
  }) %>% bind_rows()
  ls_enum[sapply(ls_enum, is.null)] <- NULL
  ls_enum <- bind_rows(ls_enum)
  return(list(custom_fields = ls_df,
              custom_fields_enum = ls_enum))
}

#' @importFrom httr GET
#' @importFrom httr content
get_timezone <- function(email = NULL, apikey = NULL, domain = NULL) {
  answer <- GET(paste0("https://",domain,".amocrm.ru/api/v2/account"))
  dataRaw <- content(answer, "parsed", "application/json")
  timezone <- dataRaw$timezone
  timezone
}

get_datetime <- function(dataframe, columns, email = NULL, apikey = NULL, domain = NULL) {
  tz <- get_timezone(email, apikey, domain)
  dataframe[columns] <- lapply(dataframe[columns], function(x) return(as.POSIXct(as.integer(x), origin = '1970-01-01', tz = tz)))
  dataframe
}
