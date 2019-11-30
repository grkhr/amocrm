#' Customers transactions
#'
#' Function to get transactions of customers. Please read the following manual on github: \code{\link{https://github.com/grkhr/amocrm}}.
#'
#' Check api params if needed: \code{\link{https://www.amocrm.ru/developers/content/api/unsorted}}
#' @param email Email
#' @param apikey Your api key from settings in interface
#' @param domain Your domain in AmoCRM (xxx in xxx.amocrm.ru)
#' @param auth_list List with auth data, you can build from AmoAuthList
#' @param limit Batch limit, sometimes AmoCRM's API doesn't work properly, you can reduce the value and have a chance to load your data
#' @param id Filter. Pass id of transaction.
#' @param customer_id Filter. Pass id of customer to get transaction from its. You can get ids from AmoCustomers().
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
#' # get all
#' transactions <- AmoCustomersTransations(auth_list = auth_list)

AmoCustomersTransactions <- function(email = NULL, apikey = NULL, domain = NULL, auth_list = NULL, limit = 500,
                             id = NULL, customer_id = NULL) {
  # auth
  if (!is.null(auth_list)) {
    email <- auth_list$email
    apikey <- auth_list$apikey
    domain <- auth_list$domain
  }
  auth <- AmoAuth(email, apikey, domain, verbose=F)
  if (auth != T) stop(auth)

  packageStartupMessage('Processing transactions...')
  tic()
  options(warn = -1)
  options(scipen=999)
  options(stringsAsFactors = F)

  # batch limit
  limit_rows = limit
  # first offset
  limit_offset = 0
  # variable limit
  limit_limit = limit
  # max before reauth
  auth_limit = limit * 20

  transactions_all = data.frame()

  # main
  while (limit_limit == limit) {

    # auth if too long
    if ((limit_offset * limit_rows) %% (auth_limit - auth_limit %% limit) == 0) {
      auth <- AmoAuth(email, apikey, domain, verbose=F)
      if (auth != T) stop(auth)
    }
    # query params
    que_easy <- list(id = pasteNULL(id),
                     customer_id = pasteNULL(id)
    )
    que <- build_query(que_easy)

    answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/transactions"), query=que)
    dataRaw <- content(answer, "parsed", "application/json")

    transactions <- dataRaw$`_embedded`$items
    last_limit <- limit_offset
    limit_limit <- length(transactions)
    # amo bug
    if (length(transactions) == 0) {
      answer <- GET(paste0("https://", domain, ".amocrm.ru/api/v2/transactions"), query=que)
      dataRaw <- content(answer, "parsed", "application/json")
      transactions <- dataRaw$`_embedded`$items
      limit_limit <- length(transactions)
    }
    limit_offset <- limit_offset + limit_limit
    if (last_limit == limit_offset& last_limit != 0) stop("Seems that AmoCRM API doesn't work properly.
                                                   Try another limit parameter, wait some time or contact Amo technical support.")

    transactions_df <- lapply(transactions, function(x) {
      # delete
      if (!is.null(x$`_links`)) x$`_links` <- NULL
      if (!is.null(x$`_embedded`)) x$`_embedded` <- NULL

      if (!is.null(x$customer)) x$customer_id <- x$customer$id
      if (!is.null(x$customer)) x$customer <- NULL

      bind_rows(unlist(x))

    }) %>% bind_rows()

    # dataframes
    transactions_all <- bind_rows(transactions_all, transactions_df)
    if (nrow(transactions_all)) {
      #inc_leads_all <- inc_leads_all %>% setNames(gsub(".", "_", names(.), fixed = T))
      transactions_all[transactions_all$comment == "",]$comment <- NA
      cols <- names(transactions_all)
      cols <- cols[grepl('_at$', cols)]
      transactions_all <- get_datetime(transactions_all, cols, email, apikey, domain)
    }

    packageStartupMessage("Transactions processed: ", nrow(transactions_all))
  }

  # warning
  options(warn = 0)
  if (nrow(transactions_all) == 0) warning("Oops... seems that you've requested zero rows")

  # main
  main_list <- transactions_all

  packageStartupMessage("_____________________")
  s <- toc(quiet = T)
  packageStartupMessage("Done. Elapsed ", as.numeric(round(s$toc - s$tic)), " seconds.")
  return(main_list)
}
