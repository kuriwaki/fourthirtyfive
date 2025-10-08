#' Load Dodged CD centroids
#'
#' Loads shapefile of coordinates. Each row contains a coordinate of the
#' centroid of the CD, slightly dodged so that points in dense places do
#' not overlap.
#'
#'
#' @param year Integer vector of years from 2005-2025.
#' @param congress Integer vector of Congress numbers from the 109th-119th Congress.
#'
#' @author Zoya Ahmer, Shiro Kuriwaki, Cory McCartan
#'
#' @return An sf object (single year) or sf/tibble (multiple years).
#'
#' @examples
#' # load one dataset
#' load_shp_dot(year = 2011) # is equivalent to loading `shp_dot_2011`
#' load_shp_dot(congress = 109)
#'
#' # load multiple datasets
#' load_shp_dot(year = c(2005, 2009, 2011))
#' load_shp_dot(congress = c(109, 110))
#'
#' # plot points combined with state outline
#' library(ggplot2)
#'
#' load_shp_dot(year = 2005) |>
#'   ggplot() +
#'   geom_sf(data = shp_states) +
#'   geom_sf(size = 1, alpha = 0.5)
#'
#' # can also use ggforce::geom_circle, extracting x,y coordinates from geom and
#' # setting a radius e.g. to 150000
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
    utils::data(list = obj, package = "fourthirtyfive", envir = environment())

    if (!exists(obj, envir = environment(), inherits = FALSE)) {
      stop(sprintf("Year not available.", obj),
        call. = FALSE
      )
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
