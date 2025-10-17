#' Download CD Shapes
#'
#' Download shapefiles (`sf` objects) for U.S. congressional districts for a
#' given Congress number (1-119th).
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
#' @examples
#' library(sf)
#' library(ggplot2)
#'
#' # Load the 109th Congress shapefile
#' cd109 <- load_cd_shps(congress = 109)
#' cd108 <- load_cd_shps(year = 2003)
#'
#' # Load the 109th and 110th Congress shapefile
#' cd109_110 <- load_cd_shps(congress = c(109, 110))
#'
#' # Create a map with cd boundaries
#' cd109 |>
#'   ggplot() +
#'   geom_sf()
#'
#' @importFrom utils data
#' @importFrom rlang .data
#' @importFrom sf st_transform st_make_valid
#' @importFrom stringr str_remove str_pad
#' @importFrom dplyr filter mutate rename select left_join distinct bind_rows pick starts_with if_else
#' @return An sf object with CD boundaries for the requested Congress.
#' @export

load_cd_shps <- function(year = NULL, congress = NULL, epsg = 5070) {

  if (!is.null(congress)) {
    congress <- as.integer(congress)
  } else {
    congress <- year_to_cong(year)
  }

  # load one congress
  load_one <- function(ci) {
    ci <- as.integer(ci)
    year <- as.integer(cong_to_firstyear(ci))

    if (ci <= 112) {
      utils::data("state", package = "datasets", envir = environment())
      sf_obj <- purrr::map_df(state_abb, purrr::possibly(~ geomander::get_lewis(state = .x, congress = ci), NULL)) |>
        mutate(
          geometry = st_make_valid(.data$geometry),
          year = as.integer(cong_to_firstyear(ci))
          ) |>
        st_transform(crs = epsg) |>
        rename(dist = district) |>
        filter(.data$statename != "District of Columbia") |>
        mutate(
          st = state_abb[match(.data$statename, state.name)],
          dist_chr = as.character(.data$dist),
          dist_chr = if_else(.data$dist_chr == "" | is.na(.data$dist_chr), "1", .data$dist_chr),
          cd = paste0(.data$st, "-", str_pad(.data$dist_chr, 2, pad = "0"))
        ) |>
        mutate(congress = ci) |>
        select("year", "congress", "cd", "geometry")
    } else if (ci >= 113 && ci <= 119) {
      year_in <- if (ci == 119) 2024L else year

      sf_obj <- tigris::congressional_districts(
        year = year_in,
        cb = TRUE,
        resolution = "20m"
      ) |>
        mutate(geometry = st_make_valid(.data$geometry)) |>
        # remove PR, territories
        filter(!.data$STATEFP %in% c("72", "60", "66", "69", "78")) |>
        st_transform(crs = epsg) |>
        mutate(
          STATEFP = as.character(.data$STATEFP),
          year = as.integer(cong_to_firstyear(ci))
        ) |>
        left_join(
          tigris::fips_codes |>
            select(STATEFP = .data$state_code, state_abb = state, statename = .data$state_name) |>
            distinct(),
          by = "STATEFP"
        ) |>
        filter(.data$statename != "District of Columbia") |>
        mutate(
          dist_chr = str_remove(pick(starts_with("CD"))[[1]], "^0+"),
          dist_chr = if_else(.data$dist_chr == "" | is.na(.data$dist_chr), "1", .data$dist_chr),
          cd = paste0(.data$state_abb, "-", stringr::str_pad(.data$dist_chr, 2, pad = "0"))
        ) |>
        mutate(congress = ci) |>
        select("year", "congress", "cd", "geometry")
    } else {
      stop("Congress number greater than 119 is not yet supported.", call. = FALSE)
    }
    sf_obj |>
      mutate(
        congress = ci,
        year = if (ci == 119) 2024L else year
      )
  }

  bind_rows(lapply(congress, load_one))
}
