#' Load congressional district info
#'
#' This function returns one or more of the `info_*` datasets
#'
#' @param year Integer vector of years (e.g., `2011` or `c(2005, 2009, 2011)`).
#' @param congress Integer vector of Congress numbers
#'
#' @return A tibble with congressional district info for the requested year.
#' @examples
#' # load one dataset
#' load_cd_info(year = 2011)
#' load_cd_info(congress = 109)
#'
#' # load multiple datasets
#' load_cd_info(year = c(2005, 2007, 2009))
#'
#' @export
load_cd_info <- function(year = NULL, congress = NULL) {

  if (!is.null(year)) {
    congress <- year_to_cong(year)
    } else if (!is.null(congress)) {
    year <- cong_to_firstyear(congress)
    }

  # one dataset
  load_one <- function(y) {
    nm <- paste0("info_", y)
    utils::data(list = nm, package = "cdmap", envir = environment())
    if (!exists(nm, envir = environment(), inherits = FALSE)) {
      stop(sprintf("`%s` not found in package data. Check available years.", nm), call. = FALSE)
    }
    get(nm, envir = environment())
  }

  out_list <- lapply(unique(year), load_one)

  if (length(out_list) == 1L) {
    out_list[[1]]
  } else {
    dplyr::bind_rows(out_list)
  }
}
