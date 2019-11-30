#' @importFrom curl curl_escape
build_query <- function(elements) {
  if (length(elements) == 0) {
    return("")
  }

  elements <- Filter(Negate(is.null), elements)

  names <- curl::curl_escape(names(elements))

  encode <- function(x) {
    if (inherits(x, "AsIs")) return(x)
    curl::curl_escape(x)
  }
  values <- vapply(elements, encode, character(1))

  paste0(names, "=", values, collapse = "&")
}

#' @importFrom curl curl_escape
build_query_array <- function(elements) {
  elements <- Filter(Negate(is.null), elements)
  if (length(elements) == 0) {
    return("")
  }

  ls <- data.frame()
  for (i in 1:length(elements))
    for (j in 1:length(elements[[i]]))
      ls <- rbind(ls,
                  data.frame(name = names(elements[i]),
                             value = elements[[i]][j])
      )

  names <- curl::curl_escape(ls$name)

  encode <- function(x) {
    if (inherits(x, "AsIs")) return(x)
    curl::curl_escape(x)
  }
  values <- vapply(ls$value, encode, character(1))

  paste0(names, "=", values, collapse = "&")
}

pasteNULL <- function(x) {
  return(if(is.null(x)) NULL else paste(x, collapse = ","))
}

build_full_query <- function(easy, arr) {
  paste0(build_query(easy), "&", build_query_array(arr))
}
