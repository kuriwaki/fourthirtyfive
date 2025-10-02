#' Load dot-map point datasets
#'
#' This function returns one or more of the `shp_dot_*` datasets.
#'
#' @param year Integer vector of years from 2005-2025.
#' @param congress Integer vector of Congress numbers from the 109th-119th Congress.
#'
#' @return An sf object (single year) or sf/tibble (multiple years).
#' @examples
#' # load one dataset
#' load_shp_dot(year = 2011)
#' load_shp_dot(congress = 109)
#'
#' # load multiple datasets
#' load_shp_dot(year = c(2005, 2009, 2011))
#' load_shp_dot(congress = c(109, 110))
#'
#' @export
load_shp_dot <- function(year = NULL, congress = NULL) {

  if (!is.null(year)) {
    congress <- year_to_cong(year)
  } else if (!is.null(congress)) {
    year <- cong_to_firstyear(congress)
  }

  year <- as.integer(year)
  if (anyNA(year)) stop("`year` must be integer years like 2011 or 2005:2009.", call. = FALSE)

  one <- function(y) {
    obj <- paste0("shp_dot_", y)

    # load from data/ (works when package is installed)
    utils::data(list = obj, package = "cdmap", envir = environment())

    if (!exists(obj, envir = environment(), inherits = FALSE)) {
      stop(sprintf("Year not available.", obj),
           call. = FALSE)
    }

    obj <- get(obj, envir = environment())

  }

  lst <- lapply(year, one)

  if (length(year) == 1L) {
    lst[[1]]
  } else {
    # bind rows across years
    dplyr::bind_rows(lst)
  }
}

#' List all available years for shp_dot datasets in data/
#'
#' @return Vector of years for which `shp_dot_*` works
#' @examples
#' shp_dot_years
#' @export
shp_dot_years <- c("shp_dot_2005", "shp_dot_2007", "shp_dot_2009",
                   "shp_dot_2011", "shp_dot_2013", "shp_dot_2015",
                   "shp_dot_2017", "shp_dot_2019", "shp_dot_2021",
                   "shp_dot_2023", "shp_dot_2025")
