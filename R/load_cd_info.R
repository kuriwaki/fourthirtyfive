#' Load congressional district info
#'
#' This function returns one or more of the `info_*` datasets
#'
#' @param yrs Integer vector of years (e.g., `2011` or `c(2005, 2009, 2011)`).
#'
#' @return A tibble with congressional district info for the requested yrs.
#' @examples
#' # load one dataset
#' load_cd_info(2011)
#'
#' # load multiple datasets
#' load_cd_info(c(2005, 2007, 2009))
#'
#' @export
load_cd_info <- function(yrs) {
  yrs <- as.integer(yrs)

  one <- function(y) {
    nm <- paste0("info_", y)
    # load dataset from data/
    utils::data(list = nm, package = "cdmap", envir = environment())
    obj <- get(nm, envir = environment())
  }

  out_list <- lapply(yrs, one)

  # if load one year
  if (length(yrs) == 1L) {
    out_list[[1]]
  } else {
    # if more than one year is loaded
    dplyr::bind_rows(out_list)
  }
}
