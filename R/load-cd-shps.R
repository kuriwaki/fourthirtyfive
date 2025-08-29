#' Download CD Shapes
#'
#' Download shapefiles (`sf` objects) for U.S. congressional districts for a
#' given Congress number (109-119th).
#'
#' @name load_cd_shps
#' @title Download CD Shapes
#'
#' @param c integer, choose a congress number (109–119) to load.
#' @param 5070 integer EPSG code for output CRS (default 5070).
#'
#' @format Each object is the sf for a particular congress. The year indicates
#'  the start of that congress
#' @source Shapefiles from 2012 onwards taken from US Census, `tigris` package.
#'  Shapefiles from early congresses are taken from Jeffrey B. Lewis,
#'  historical congressional district shapefiles.
#'
#' @examples
#' library(sf)
#' library(ggplot2)
#'
#' # Load the 109th Congress shapefile
#' cd109 <- load_cd_shps(109)
#'
#' # Create a map with cd boundaries
#' cd109 |>
#'   ggplot() +
#'   geom_sf()
#'
#' @importFrom utils data
#' @importFrom sf st_transform
#' @return An sf object with CD boundaries for the requested Congress.
#' @export

library(sf)

load_cd_shps <- function(c) {

  if (c <= 112) {
    # use possibly() and otherwise so VA doesn't stop whole func
    utils::data("state", package = "datasets", envir = environment())
    sf <- purrr::map_df(state.abb,
                        purrr::possibly(~ geomander::get_lewis(state = .x, congress = c), NULL)) |>
      sf::st_transform(crs = 5070)

  } else if (c >= 113 & c <= 118) {
    yr <- 2 * c + 1786 + 1
    sf <- tigris::congressional_districts(year = yr, cb = TRUE, resolution = "20m") |>
      # remove PR, territories
      dplyr::filter(!STATEFP %in% c("72", "60", "66", "69", "78")) |>
      st_transform(crs = 5070)

  } else if (c == 119) {
    # 2024 shapefile for 119th
    sf <- tigris::congressional_districts(year = 2024, cb = TRUE, resolution = "20m") |>
      dplyr::filter(!STATEFP %in% c("72", "60", "66", "69", "78")) |>
      sf::st_transform(crs = 5070)
  }
  sf
}

