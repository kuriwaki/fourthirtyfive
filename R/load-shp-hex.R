#' @title Load Daily Kos Elections Cartogram
#'
#' @description Loads Daily Kos Elections cartogram shapefile of coordinates for each district.
#'
#' @param year Integer vector of years from 2019-2025.
#' @param congress Integer vector of Congress numbers from the 109th-119th Congress.
#'
#' @return An sf object (single year) or sf/tibble (multiple years).
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
#'   geom_sf()
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

  one <- function(y) {
    obj <- paste0("shp_hex_", y)

    # load from data/ (works when package is installed)
    utils::data(list = obj, package = "fourthirtyfive", envir = environment())

    if (!exists(obj, envir = environment(), inherits = FALSE)) {
      stop(sprintf("Only years 2021-2025 (116th-119th Congresses) available at this time.", obj),
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
#' @aliases shp_hex_2019 shp_hex_2021 shp_hex_2023 shp_hex_2025
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
