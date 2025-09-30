#' Download CD Shapes
#'
#' Download shapefiles (`sf` objects) for U.S. congressional districts for a
#' given Congress number (1-119th).
#' Download shapefiles for U.S. congressional districts for a
#' given Congress number (109-119th).
#'
#' @name load_cd_shps
#' @title Download CD Shapes
#' @param year integer, choose a year to load
#' @param congress integer, choose a congress number (1–119) to load (optional).
#' Optional if `congress` is given.
#' @param epsg integer EPSG code for output CRS (default 5070).
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
#' cd109 <- load_cd_shps(congress = 109)
#' cd108  <- load_cd_shps(year = 2003)
#'
#' # Load the 109th and 110th Congress shapefile
#' cd109_110 <- load_cd_shps(congress = c(109,110))
#'
#' # Create a map with cd boundaries
#' cd109 |>
#'   ggplot() +
#'   geom_sf()
#'
#' @importFrom utils data
#' @importFrom sf st_transform
#' @importFrom rlang .data
#' @return An sf object with CD boundaries for the requested Congress.
#' @export
load_cd_shps <- function(year = NULL, congress = NULL, epsg = 5070) {

  if (is.null(congress) && is.null(year))
    stop("Provide `congress` or `year`.", call. = FALSE)

  if (is.null(congress))congress <- year_to_cong(year)
  if (is.null(year))year <- cong_to_firstyear(congress)

  # allow length-1 recycling
  if (length(congress) != length(year)) {
    if (length(congress) == 1L) congress <- rep.int(congress, length(year))
    else if (length(year) == 1L) year <- rep.int(year, length(congress))
    else stop("`congress` and `year` must have same length.", call. = FALSE)
  }

  # normalize
  congress <- as.integer(congress)
  year <- as.integer(cong_to_firstyear(congress))

  # load one congress
  load_one <- function(ci, yr) {
    ci <- as.integer(ci)[1]
    yr <- as.integer(yr)[1]

    if (ci <= 112) {
      utils::data("state", package = "datasets", envir = environment())
      sf_obj <- purrr::map_df(
        state.abb,
        purrr::possibly(~ geomander::get_lewis(state = .x, congress = ci), NULL)
      ) |>
        sf::st_transform(crs = epsg)

    } else if (ci >= 113 && ci <= 118) {
      sf_obj <- tigris::congressional_districts(year = yr, cb = TRUE, resolution = "20m") |>
        dplyr::filter(!(.data$STATEFP %in% c("72","60","66","69","78"))) |>
        sf::st_transform(crs = epsg)

    } else if (ci == 119) {
      sf_obj <- tigris::congressional_districts(year = 2024, cb = TRUE, resolution = "20m") |>
        dplyr::filter(!(.data$STATEFP %in% c("72","60","66","69","78"))) |>
        sf::st_transform(crs = epsg)

    } else {
      stop("Congress number greater than 119 is not yet supported.", call. = FALSE)
    }

    dplyr::mutate(sf_obj,
                  congress = ci,
                  year     = if (ci == 119) 2024L else yr)
  }

  dplyr::bind_rows(Map(load_one, congress, year))
}
