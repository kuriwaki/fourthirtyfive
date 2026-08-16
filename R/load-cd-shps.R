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
#' # Create a map with cd boundaries
#' cd109 |>
#'   ggplot() +
#'   geom_sf()
#'
#' @importFrom utils data
#' @importFrom rlang .data
#' @importFrom sf st_transform st_make_valid st_crs st_as_sf
#' @importFrom stringr str_remove str_pad
#' @importFrom dplyr filter mutate rename select left_join distinct bind_rows pick starts_with if_else case_when
#' @importFrom tibble tibble
#' @importFrom urbnmapr get_urbn_map
#' @return An sf object with CD boundaries for the requested Congress.
#' @export

# Work around geomander::get_lewis() returning NA URLs (e.g. Georgia).
get_lewis_sf <- function(state, congress) {
  urls <- geomander::get_lewis(state = state, congress = congress, path_only = TRUE)
  if (all(is.na(urls))) {
    warning(sprintf("No Lewis shapefile found for %s (congress %s).", state, congress), call. = FALSE)
    return(NULL)
  }
  sf::read_sf(urls[!is.na(urls)][1])
}

# Parameter
# https://r-spatial.github.io/sf/articles/sf3.html#affine-transformations
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
      sf_obj <- purrr::map_df(state_abb, ~ get_lewis_sf(.x, ci)) |>
        mutate(
          geometry = st_make_valid(.data$geometry),
          year = as.integer(cong_to_firstyear(ci))
        ) |>
        st_transform(crs = epsg) |>
        filter(!.data$statename %in% c("District of Columbia")) |>
        mutate(
          st = datasets::state.abb[match(.data$statename, datasets::state.name)],
          dist_chr = stringr::str_remove(as.character(.data$district), "^0+"),
          dist_chr = if_else(.data$dist_chr == "" | is.na(.data$dist_chr), "1", .data$dist_chr),
          cd = paste0(.data$st, "-", str_pad(.data$dist_chr, 2, pad = "0"))
        ) |>
        mutate(congress = ci) |>
        select("year", "congress", "cd", "geometry")

      # AK and HI
      akhi_sf <- get_urbn_map("states", sf = TRUE) |>
        filter(.data$state_abbv %in% c("AK", "HI")) |>
        mutate(
          geometry = case_when(
            .data$state_abbv == "AK" ~ geometry + c(-0.3e6, 2.5e6),
            TRUE ~ (geometry + c(-0.15e6, 2.26e6)) * rot(pi / 16) * 1.2
          )
        ) |>
        select(.data$state_abbv, .data$geometry)

      akhi_sf <- tibble(
        cd = c("AK-01", "HI-01", "HI-02"),
        geometry = c(
          akhi_sf$geometry[akhi_sf$state_abbv == "AK"],
          rep(akhi_sf$geometry[akhi_sf$state_abbv == "HI"], 2)
        )
      ) |>
        st_as_sf(crs = 5070)

      sf_obj <- sf_obj |> filter(!grepl("^(AK|HI)-", .data$cd))
      akhi_sf <- mutate(akhi_sf, year = year, congress = ci)
      sf_obj <- bind_rows(sf_obj, akhi_sf)

    } else if (ci >= 113 && ci <= 119) {
      year_in <- if (ci == 119) 2024L else year

      sf_obj <- tigris::congressional_districts(
        year = year_in,
        cb = TRUE,
        resolution = "20m"
      ) |>
        mutate(geometry = st_make_valid(.data$geometry)) |>
        # remove PR, territories, AK, HI
        filter(!.data$STATEFP %in% c("72", "60", "66", "69", "78")) |>
        st_transform(crs = epsg) |>
        mutate(
          STATEFP = as.character(.data$STATEFP),
          year = as.integer(cong_to_firstyear(ci))
        ) |>
        left_join(
          tigris::fips_codes |>
            select(STATEFP = .data$state_code, state_abb = .data$state, statename = .data$state_name) |>
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

      # AK and HI
      akhi_sf <- get_urbn_map("states", sf = TRUE) |>
        filter(.data$state_abbv %in% c("AK", "HI")) |>
        mutate(
          geometry = case_when(
            .data$state_abbv == "AK" ~ geometry + c(-0.3e6, 2.5e6),
            TRUE ~ (geometry + c(-0.15e6, 2.26e6)) * rot(pi / 16) * 1.2
          )
        ) |>
        select(.data$state_abbv, .data$geometry)

      akhi_sf <- tibble(
        cd = c("AK-01", "HI-01", "HI-02"),
        geometry = c(
          akhi_sf$geometry[akhi_sf$state_abbv == "AK"],
          rep(akhi_sf$geometry[akhi_sf$state_abbv == "HI"], 2)
        )
      ) |>
        st_as_sf(crs = 5070)

      sf_obj$geometry[match(akhi_sf$cd, sf_obj$cd)] <- akhi_sf$geometry

    } else {
      stop("Congress number greater than 119 is not yet supported.", call. = FALSE)
    }

    sf_obj <- sf_obj |>
      mutate(
        congress = ci,
        year = if (ci == 119) 2024L else year
      )

  }

  bind_rows(lapply(congress, load_one))
}
