#' Convert Congressional session to the start year of that Congress
#' @param congress integer or numeric vector
#' @return integer vector of start years
#' @examples
#' cong_to_firstyear(1)     # 1789
#' cong_to_firstyear(109)   # 2005
#' cong_to_firstyear(c(108,109)) # 2003 2005
#' @export
cong_to_firstyear <- function(congress) {
  if (!is.numeric(congress)) stop("Congress must be an integer.", call. = FALSE)
  out <- 1787L + 2L * as.integer(congress)
  out[is.na(congress)] <- NA_integer_
  out
}

#' Convert year of Congress to Congressional session
#' @param year integer or numeric vector of years
#' @return integer vector of Congress numbers
#' @examples
#' year_to_cong(2003) # 108
#' year_to_cong(c(2003, 2005)) # 108, 109
#' @export
year_to_cong <- function(year) {
  if (!is.numeric(year)) stop("Year must be an integer.", call. = FALSE)
  out <- as.integer((as.integer(year) - 1789L) %/% 2L + 1L)
  out[is.na(year)] <- NA_integer_
  out
}
