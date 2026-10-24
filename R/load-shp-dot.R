#' @title Load Dodged CD centroids
#'
#' @description Loads shapefile of coordinates. Each row contains a coordinate of the
#' centroid of the CD, slightly dodged so that points in dense places do
#' not overlap.
#'
#'
#' @param year Integer vector of years from 2005-2027.
#' @param congress Integer vector of Congress numbers from the 109th-120th Congress.
#'
#' @author Zoya Ahmer, Shiro Kuriwaki, Cory McCartan
#'
#' @return An sf object (single year) or sf/tibble (multiple years).
#'
#' @examples
#' # load one dataset
#' load_shp_dot(year = 2011) # is equivalent to loading `shp_dot_2011`
#' load_shp_dot(congress = 109)
#' load_shp_dot(year = 2027)
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
#' @name load_shp_dot
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

#' @title Dotmap: Dodged CD centroids
#' @name shp_dot
#' @docType data
#' @keywords datasets
#' @description Shapefile of coordinates. Each row contains a coordinate of the centroid of the CD,
#'  slightly dodged so that points in dense places do not overlap.
#'
#' @format Each object is for a particular congress. The year indicates the start
#'  of that Congress. Each observational is a congressional district, represented by
#'  a point.
#' @source Coordinates from 2012 onwards taken from US Census, `tigris` package.
#'  Coordinates from early Congresses taken from Jeffrey B. Lewis, historical congressional
#'  district shapefiles
#'
#'  For 2027, we use tigris v.2.3.0 as of October 24 2026 to get the new centers in
#'  AL, CA, FL, LA, NC, OH, TN, TX, and UT, and reuse the previous cycle's dots
#'  for other states.
#'
#' @aliases shp_dot_2005 shp_dot_2007 shp_dot_2009 shp_dot_2011 shp_dot_2013
#' @aliases shp_dot_2015 shp_dot_2017 shp_dot_2019 shp_dot_2021 shp_dot_2023 shp_dot_2025
#' @aliases shp_dot_2027
#'
#' @examples
#' library(sf)
#' library(ggplot2)
#'
#' shp_dot_2023
#'
#' # plot points combined with state outline
#' shp_dot_2005 |>
#'   ggplot() +
#'   geom_sf(data = shp_states) +
#'   geom_sf(size = 1, alpha = 0.5)
#'
#' # can also use ggforce::geom_circle, extracting x,y coordinates from geom and
#' # setting a radius e.g. to 150000
NULL
