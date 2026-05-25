#' @title Load Daily Kos / Downballot Elections Cartogram
#'
#' @description Loads Daily Kos Elections cartogram shapefile of each district.
#'
#' @param year Integer vector of years. Currently accepts 2009 or 2013-2025.
#' @param congress Integer vector of Congress numbers. Currently accepts 111 or 113-119.
#'
#' @details Years indicate the year of the January in which the Congress starts.
#'  For example, to get shapefiles for the 2022 election, set `year = 2023`.
#'
#'
#' @note For 2013 to 2021, we use the same shapefile (Downballot's v2.1wm), but note that
#'  between the 2016 and 2020 data, PA changed their districts but did not add/remove any.
#'  Between the 2012-14 and 2016 data, FL, NC, VA did mid-cycle redistricting.
#'  The 2009 hexmap (111th Congress / 2008 election) is created through Cory McCartan's
#'  \href{https://github.com/CoryMcCartan/hexmap}{hexmap} package rather than a pre-made
#'  Daily Kos shapefile, since one does not exist for that Congress.
#'
#' @author Daniel Donner (2013–2025 shapefiles); Cory McCartan (2009 hexmap generation)
#' @source 2013–2025: \url{https://the-db.co/maps}. 2009: created with
#'   \href{https://github.com/CoryMcCartan/hexmap}{CoryMcCartan/hexmap} using
#'   district boundaries from Jeffrey B. Lewis's historical shapefiles.
#' @return An sf dataframe with 435 rows
#'
#' @examples
#' # load one dataset
#' load_shp_hex(year = 2019)
#'
#' # plot points combined with state outline
#' library(ggplot2)
#'
#' load_shp_hex(year = 2019) |>
#'   ggplot() +
#'   geom_sf() +
#'   theme_void()
#'
#' @name load_shp_hex
#' @export

load_shp_hex <- function(year = NULL, congress = NULL) {
  if (!is.null(year)) {
    congress <- year_to_cong(year)
  } else if (!is.null(congress)) {
    year <- cong_to_firstyear(congress)
  }
  year <- as.integer(year)
  if (anyNA(year)) stop("`year` must be integer years like 2011 or 2005:2009.", call. = FALSE)
  if (any(year %% 2 == 0)) stop("As of now, only odd years for the start of each Congress are available.", call. = FALSE)

  one <- function(y) {
    obj <- paste0("shp_hex_", y)
    utils::data(list = obj, package = "fourthirtyfive", envir = environment())
    if (!exists(obj, envir = environment(), inherits = FALSE)) {
      stop("Available years are 2009 or odd years between 2013-2025.", call. = FALSE)
    }
    get(obj, envir = environment())
  }

  lst <- lapply(year, one)
  if (length(year) == 1L) {
    lst[[1]]
  } else {
    dplyr::bind_rows(lst)
  }
}

#' @title Hexmap: Daily Kos / Downballot Elections Cartogram
#' @name shp_hex
#' @docType data
#' @keywords datasets
#' @description Loads Daily Kos / Downballot Elections cartogram shapefile of coordinates for each district.
#'
#' @format Each object is for a particular year. The year indicates the start
#'  of that Congress. Each observational is a congressional district, represented by
#'  a cartogram.
#' @source 2013–2025 coordinates are from The Downballot's maps database.
#'   2009 (\code{shp_hex_2009}) is created through \href{https://github.com/CoryMcCartan/hexmap}{CoryMcCartan/hexmap}.
#'
#' @aliases shp_hex_2009 shp_hex_2013 shp_hex_2015 shp_hex_2017 shp_hex_2019 shp_hex_2021 shp_hex_2023 shp_hex_2025
#'
#' @examples
#' library(sf)
#' library(ggplot2)
#'
#' shp_hex_2019 |>
#'   ggplot() +
#'   geom_sf() +
#'   theme_bw()
NULL
