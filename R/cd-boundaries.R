# Written by Codex
#' Congressional district boundaries
#'
#' @description Download `sf` boundaries for U.S. congressional districts for a
#' given Congress number (1-120th).
#'
#' @name cd_boundaries
#' @inheritParams cd_params
#'
#' @details Supply `year` or `congress`. Boundaries cover Congresses 1-120
#'   (start years 1789-2027). Leave `state = NULL` for all states, or supply
#'   one or more states to select their districts.
#'
#'   For 2027 (120th Congress), we use the 2026 Census TIGER for
#'  AL, CA, FL, LA, NC, OH, TN, TX, and UT (with middecade redistricting), and
#'  reuse the previous cycle's boundaries for all other states.
#'
#' @format Each object is the sf for a particular congress. The year indicates
#'  the start of that congress
#' @source Shapefiles from 2012 onwards taken from US Census, `tigris` package.
#'  Shapefiles from early congresses are taken from Jeffrey B. Lewis,
#'  historical congressional district shapefiles.
#'  For the 120th Congress, see the Census boundary collection and Missouri
#'  correction notice:
#'  \url{https://www.census.gov/programs-surveys/decennial-census/about/rdo/congressional-districts.html}
#' @examples
#' library(sf)
#' library(ggplot2)
#'
#' # Load the 109th Congress shapefile
#' \dontrun{
#' cd109 <- cd_boundaries(congress = 109)
#' cd108 <- cd_boundaries(year = 2003)
#'
#' # Districts used for the Congress starting in January 2027
#' cd120 <- cd_boundaries(year = 2027)
#'
#' # Create a map with cd boundaries
#' cd109 |>
#'   ggplot() +
#'   geom_sf()
#' }
#'
#' @importFrom utils data
#' @importFrom rlang .data
#' @importFrom sf st_transform st_make_valid st_crs st_as_sf st_simplify
#' @importFrom stringr str_remove str_pad
#' @importFrom dplyr filter mutate rename select left_join distinct bind_rows pick starts_with if_else case_when
#' @importFrom tibble tibble
#' @return An sf object with CD boundaries for the requested Congress.
#' @family congressional district functions
#' @seealso [cd_available()] for supported years and Congresses.
#' @export
# Parameter
# https://r-spatial.github.io/sf/articles/sf3.html#affine-transformations
cd_boundaries <- function(year = NULL, congress = NULL, epsg = 5070, simplify = TRUE, cache = TRUE, state = NULL) {

  state <- normalize_cd_states(state)

  if (!is.null(congress)) {
    congress <- as.integer(congress)
  } else {
    congress <- year_to_cong(year)
  }

  # load one congress
  load_one <- function(ci) {
    ci <- as.integer(ci)
    year <- as.integer(cong_to_firstyear(ci))
    cache_key <- stringr::str_glue("{isTRUE(simplify)}:{paste(state, collapse = ',')}")
    if (ci == 120L && isTRUE(cache) && exists(cache_key, .cd_map_cache, inherits = FALSE)) {
      return(project_cd_map(get(cache_key, .cd_map_cache), epsg))
    }

    if (ci <= 112) {
      utils::data("state", package = "datasets", envir = environment())
      requested_states <- if (is.null(state)) state_abb else state
      sf_obj <- purrr::map_df(requested_states, ~ get_lewis_sf(.x, ci)) |>
        mutate(
          geometry = st_make_valid(.data$geometry),
          year = as.integer(cong_to_firstyear(ci))
        ) |>
        st_transform(crs = 5070)

      # 5000m in EPSG:5070 matches Census cartographic 20m vertex density
      if (isTRUE(simplify)) {
        sf_obj <- mutate(
          sf_obj,
          geometry = st_make_valid(st_simplify(.data$geometry, dTolerance = 5000, preserveTopology = TRUE))
        )
      }

      sf_obj <- sf_obj |>
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
      if (is.null(state) || any(state %in% c("AK", "HI"))) {
        akhi_sf <- get_cd_insets()

        sf_obj <- sf_obj |> filter(!grepl("^(AK|HI)-", .data$cd))
        akhi_sf <- mutate(akhi_sf, year = year, congress = ci)
        sf_obj <- bind_rows(sf_obj, akhi_sf) |>
          filter(is.null(state) | substr(.data$cd, 1, 2) %in% state)
      }

    } else if (ci >= 113 && ci <= 120) {
      census_input <- if (is.null(state)) get_census_cd_sf(ci) else get_census_cd_sf(ci, state = state)
      census_map <- census_input |>
        mutate(year = if (ci == 119) 2024L else year, congress = ci) |>
        select("year", "congress", "cd", "geometry")

      # AK and HI
      if (is.null(state) || any(state %in% c("AK", "HI"))) {
        akhi_sf <- get_cd_insets()

        inset_rows <- match(census_map$cd, akhi_sf$cd)
        census_map$geometry[!is.na(inset_rows)] <- akhi_sf$geometry[inset_rows[!is.na(inset_rows)]]
      }
      output_map <- if (ci == 120L && isTRUE(simplify)) {
        simplify_cd_2027(census_map)
      } else {
        census_map
      }
      if (ci == 120L && isTRUE(cache)) assign(cache_key, output_map, .cd_map_cache)
      return(project_cd_map(output_map, epsg))

    } else {
      stop("Congress number greater than 120 is not yet supported.", call. = FALSE)
    }

    sf_obj <- sf_obj |>
      mutate(
        congress = ci,
        year = if (ci == 119) 2024L else year
      )

  }

  bind_rows(lapply(congress, load_one))
}

# Reuse the state map's insets with modern CRS metadata ----
get_cd_insets <- function() {
  states <- getExportedValue("fourthirtyfive", "shp_states")
  sf::st_sf(
    cd = c("AK-01", "HI-01", "HI-02"),
    geometry = sf::st_geometry(states)[match(c("AK", "HI", "HI"), states$state)]
  )
}

# Simplify assembled 2027 maps and retain them for repeat calls ----
.cd_map_cache <- new.env(parent = emptyenv())

normalize_cd_states <- function(state) {
  if (is.null(state)) return(NULL)
  states <- dplyr::distinct(tigris::fips_codes, .data$state, .data$state_name, .data$state_code)
  input <- stringr::str_pad(toupper(trimws(as.character(state))), 2, pad = "0")
  keys <- c(states$state, toupper(states$state_name), states$state_code)
  abbreviations <- rep(states$state, 3)[match(input, keys)]
  if (!length(abbreviations) || anyNA(abbreviations)) {
    stop("`state` must contain valid state names, abbreviations, or FIPS codes.", call. = FALSE)
  }
  sort(unique(abbreviations))
}

project_cd_map <- function(x, epsg) {
  if (sf::st_crs(x) == sf::st_crs(epsg)) x else st_transform(x, epsg)
}

simplify_cd_2027 <- function(x) {
  updated <- substr(x$cd, 1, 2) %in% redrawn_states_2027
  if (!any(updated)) return(x)
  # Simplify shared arcs jointly, retaining small districts and the exact
  # geometry of already generalized states, including Missouri and the insets.
  simplified <- rmapshaper::ms_simplify(
    x[updated, ], keep = 0.05, keep_shapes = TRUE, snap = FALSE
  ) |>
    sf::st_cast("MULTIPOLYGON")
  stopifnot(
    !anyDuplicated(simplified$cd), setequal(simplified$cd, x$cd[updated]),
    all(sf::st_is_valid(simplified)), !any(sf::st_is_empty(simplified))
  )
  result <- x
  sf::st_geometry(result)[updated] <- sf::st_geometry(simplified)[match(x$cd[updated], simplified$cd)]
  result
}

# Work around geomander::get_lewis() returning NA URLs (e.g. Georgia).
get_lewis_sf <- function(state, congress) {
  urls <- geomander::get_lewis(state = state, congress = congress, path_only = TRUE)
  if (all(is.na(urls))) {
    warning(sprintf("No Lewis shapefile found for %s (congress %s).", state, congress), call. = FALSE)
    return(NULL)
  }
  sf::read_sf(urls[!is.na(urls)][1])
}

# Shared Census input for geographic maps and dot-map generation ----
redrawn_states_2027 = c("AL", "CA", "FL", "LA", "NC", "OH", "TN", "TX", "UT")

get_census_cd_sf <- function(congress, state = NULL) {
  loaded_version <- as.character(getNamespaceVersion("tigris"))
  if (congress == 120L && utils::compareVersion(loaded_version, "2.3.0") < 0L) {
    stop(stringr::str_glue(
      "2027 maps require tigris >= 2.3.0; this R session has {loaded_version} loaded. ",
      "Update tigris, restart R, and reload fourthirtyfive."
    ), call. = FALSE)
  }
  read_map <- function(year, state = NULL, cb = TRUE) {
    raw <- tigris::congressional_districts(
      state = state, year = year, cb = cb, resolution = "20m"
    )
    district_col <- grep("^CD[0-9]+FP$", names(raw), value = TRUE)
    stopifnot(length(district_col) == 1L)
    raw |>
      mutate(geometry = st_make_valid(.data$geometry), STATEFP = as.character(.data$STATEFP)) |>
      filter(!.data$STATEFP %in% c("11", "72", "60", "66", "69", "78")) |>
      st_transform(5070) |>
      left_join(
        tigris::fips_codes |>
          select(STATEFP = "state_code", state_abb = "state") |>
          distinct(),
        by = "STATEFP", relationship = "many-to-one"
      ) |>
      mutate(
        dist_chr = str_remove(.data[[district_col]], "^0+"),
        dist_chr = if_else(.data$dist_chr == "" | is.na(.data$dist_chr), "1", .data$dist_chr),
        cd = as.character(stringr::str_glue("{state_abb}-{str_pad(dist_chr, 2, pad = '0')}"))
      ) |>
      select("cd", "geometry")
  }

  if (congress == 120L) {
    if (!is.null(state)) {
      updated <- state %in% redrawn_states_2027
      selected <- bind_rows(
        if (any(updated)) read_map(2026L, state = state[updated], cb = FALSE),
        if (any(!updated)) read_map(2024L, state = state[!updated])
      )
      return(dplyr::arrange(selected, .data$cd))
    }
    baseline <- read_map(2024L)
    replacements <- read_map(2026L, state = redrawn_states_2027, cb = FALSE)
    expected <- baseline$cd[substr(baseline$cd, 1, 2) %in% redrawn_states_2027]
    stopifnot(!anyDuplicated(replacements$cd), setequal(replacements$cd, expected))
    # Retain 2025 everywhere else, including Missouri's unchanged election map.
    combined <- baseline
    sf::st_geometry(combined)[match(replacements$cd, baseline$cd)] <- sf::st_geometry(replacements)
    stopifnot(nrow(combined) == 435L, !anyDuplicated(combined$cd))
    return(dplyr::arrange(combined, .data$cd))
  }
  read_map(if (congress == 119L) 2024L else as.integer(cong_to_firstyear(congress)), state = state)
}
