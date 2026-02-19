#' @title Load Daily Kos / Downballot Elections Cartogram
#'
#' @description Loads Daily Kos Elections cartogram shapefile of each district.
#'
#' @param year Integer vector of years. Currently accepts 2019-2025.
#' @param congress Integer vector of Congress numbers from the 109th-119th Congress.
#'
#' @details Years indicate the year of the January in which the Congress starts.
#'  For example, to get shapefiles for the 2022 election, set `year = 2023`.
#'  donnermap::cd_shp is the 116th congressional shapefile (2019-2021).
#'  116th sf is used for 2016: Between the 2016 and 2020 data, PA changed their districts, but did not add/remove any.
#'
#' @author Daniel Donner
#' @source https://the-db.co/maps
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
    if (y %in% c(2015L, 2019L, 2021L)) {
      return(donnermap::cd_shp)
    }
    obj <- paste0("shp_hex_", y)
    # load from data/ (works when package is installed)
    utils::data(list = obj, package = "fourthirtyfive", envir = environment())
    if (!exists(obj, envir = environment(), inherits = FALSE)) {
      stop("Only years 2015, 2019, 2023, and 2025 are available at this time.", call. = FALSE)
    }
    get(obj, envir = environment())
  }
  lst <- lapply(year, one)
  if (length(year) == 1L) {
    lst[[1]]
  } else {
    # bind rows across years
    dplyr::bind_rows(lst)
  }
}

#' @title Hexmap: Daily Kos Elections Cartogram
#' @name shp_hex
#' @docType data
#' @keywords datasets
#' @description Loads Daily Kos Elections cartogram shapefile of coordinates for each district.
#'
#' @format Each object is for a particular year. The year indicates the start
#'  of that Congress. Each observational is a congressional district, represented by
#'  a cartogram.
#' @source Coordinates are from The Downballot's maps database.
#'
#' @aliases shp_hex_2015 shp_hex_2019 shp_hex_2021 shp_hex_2023 shp_hex_2025
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
