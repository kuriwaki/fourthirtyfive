#' Download CD Shapes
#'
#' `load_cd_shps` is a function to temporarily download shapefiles for congressional
#' Districts per congress (109-119th)
#'
#' @format Each object is the sf for a particular congress. The year indicates the start
#'  of that congress
#' @source Shapefiles from 2012 onwards taken from US Census, `tigris` package.
#'  Shapefiles from early congresses taken from Jeffrey B. Lewis, historical congressional
#'  district shapefiles
#' @examples
#' load_cd_shps(109)

#'Load CD sf
#' @param c congress number
load_cd_shps <- function(c) {

  if (c <= 112) {
    # use possibly() and otherwise so VA doesn't stop whole func
    sf <- map_df(state.abb, possibly(~ geomander::get_lewis(state = .x, congress = c), NULL))

  } else if (c >= 113 & c <= 118) {
    yr <- 2 * c + 1786 + 1
    sf <- tigris::congressional_districts(year = yr, cb = TRUE, resolution = "20m")

  } else if (c == 119) {
    # 2024 shapefile for 119th
    sf <- tigris::congressional_districts(year = 2024, cb = TRUE, resolution = "20m")
  }
  sf
}
