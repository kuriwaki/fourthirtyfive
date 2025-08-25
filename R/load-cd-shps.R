#' Download CD Shapes
#'
#' Download shapefiles (`sf` objects) for U.S. congressional districts for a
#' given Congress number (109-119th).
#'
#' @param c integer, choose a congress number (109–119) to load.
#'
#' @format Each object is the sf for a particular congress. The year indicates
#'  the start of that congress
#' @source Shapefiles from 2012 onwards taken from US Census, `tigris` package.
#'  Shapefiles from early congresses are taken from Jeffrey B. Lewis,
#'  historical congressional district shapefiles.
#'
#' @examples
#' # Load the 109th Congress shapefile
#' cd109 <- load_cd_shps(109)
#'
#' @export
#' @return An sf object with CD boundaries for the requested Congress.
load_cd_shps <- function(c) {

  if (c <= 112) {
    # use possibly() and otherwise so VA doesn't stop whole func
    sf <- purrr::map_df(state.abb, purrr::possibly(~ geomander::get_lewis(state = .x, congress = c), NULL))

  } else if (c >= 113 & c <= 118) {
    yr <- 2 * c + 1786 + 1
    sf <- tigris::congressional_districts(year = yr, cb = TRUE, resolution = "20m")

  } else if (c == 119) {
    # 2024 shapefile for 119th
    sf <- tigris::congressional_districts(year = 2024, cb = TRUE, resolution = "20m")
  }
  sf
}
