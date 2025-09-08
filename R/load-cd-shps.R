#' Download CD Shapes
#'
<<<<<<< HEAD
#' Download shapefiles (`sf` objects) for U.S. congressional districts for a
#' given Congress number (1-119th).
=======
#' Download shapefiles for U.S. congressional districts for a
#' given Congress number (109-119th).
>>>>>>> 36312ef13a8174617e2937d6b0428237164d2ef3
#'
#' @name load_cd_shps
#' @title Download CD Shapes
#'
<<<<<<< HEAD
#' @param c integer, choose a congress number (1–119) to load.
#' @param 5070 integer EPSG code for output CRS (default 5070).
=======
#' @param cong integer, choose a congress number (109–119) to load.
#' @param epsg integer EPSG code for output CRS (default 5070).
>>>>>>> 36312ef13a8174617e2937d6b0428237164d2ef3
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
load_cd_shps <- function(cong, epsg = 5070) {

<<<<<<< HEAD
library(sf)

load_cd_shps <- function(c) {

  # load one congress
  load_one <- function(ci) {
    if (ci <= 112) {
    # use possibly() and otherwise so VA doesn't stop whole func
    utils::data("state", package = "datasets", envir = environment())
    sf <- purrr::map_df(state.abb,
                        purrr::possibly(~ geomander::get_lewis(state = .x, congress = ci), NULL)) |>
      sf::st_transform(crs = 5070)

    } else if (ci >= 113 & ci <= 118) {
      yr <- 2 * ci + 1786 + 1
      sf <- tigris::congressional_districts(year = yr, cb = TRUE, resolution = "20m") |>
        # remove PR, territories
        dplyr::filter(!STATEFP %in% c("72", "60", "66", "69", "78")) |>
        st_transform(crs = 5070)

    } else if (ci == 119) {
      # 2024 shapefile for 119th
      sf <- tigris::congressional_districts(year = 2024, cb = TRUE, resolution = "20m") |>
        dplyr::filter(!STATEFP %in% c("72", "60", "66", "69", "78")) |>
        sf::st_transform(crs = 5070)

      } else if (ci > 119) {
      stop("Congress number greater than 119 is not yet supported.")
    }
    sf
  }

  if (length(c) == 1) {
    # single congress-- return one sf
    return(load_one(c))
  } else {
    # vector-- load all and bind w congress column
    res_list <- lapply(c, load_one)
    out <- dplyr::bind_rows(
      Map(function(x, ci) dplyr::mutate(x, congress = ci), res_list, c)
    )
    return(out)
=======
  if (cong <= 112) {
    # use possibly() and otherwise so VA doesn't stop whole func
    utils::data("state", package = "datasets", envir = environment())
    sf <- purrr::map_df(state.abb,
                        purrr::possibly(~ geomander::get_lewis(state = .x, congress = cong), NULL)) |>
      sf::st_transform(crs = epsg)

  } else if (cong >= 113 & cong <= 118) {
    yr <- 2 * cong + 1786 + 1
    sf <- tigris::congressional_districts(year = yr, cb = TRUE, resolution = "20m") |>
      # remove PR, territories
      dplyr::filter(!STATEFP %in% c("72", "60", "66", "69", "78")) |>
      st_transform(crs = epsg)

  } else if (cong == 119) {
    # 2024 shapefile for 119th
    sf <- tigris::congressional_districts(year = 2024, cb = TRUE, resolution = "20m") |>
      dplyr::filter(!STATEFP %in% c("72", "60", "66", "69", "78")) |>
      sf::st_transform(crs = epsg)
>>>>>>> 36312ef13a8174617e2937d6b0428237164d2ef3
  }
}


