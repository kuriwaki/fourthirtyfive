# Written by Codex

#' Interactive CD map with cities in background
#'
#' View congressional district boundaries on an interactive Mapbox map.
#' Useful for seeing how much a district overlaps with a city, or comparing multiple
#' district maps together.
#'
#' @inheritParams cd_params
#' @param cities A character name like `"Memphis"` or `"San Bernardino"` to highlight
#'  in the map.
#' @param zoom_to_cities Default to have mapbox zoom into the city, if specified?
#'  Defaults to FALSE.
#' @param colors Colors for district lines. Accepts up to three, for different
#'  Congresses.
#' @return A `mapgl` Mapbox HTML widget.
#' @details Supply exactly one district with `cd` or one state with `state`,
#'   and one to three Congress numbers from 1-120 with `congress`.
#'
#'   City outlines only use 2026
#'   Census incorporated-place boundaries, shared across the compared Congresses.
#'   They do not represent historical municipal boundaries.
#'   Alaska and Hawaii are excluded because the package's boundaries use insets.
#'
#' @seealso [mapbox-setup] for account setup, access tokens, and free usage limits.
#' @family congressional district functions
#' @examples
#' \dontrun{
#' cd_mapbox(state = "TN", congress = c(119, 120), cities = "Memphis")
#' cd_mapbox("TN-09", congress = c(119, 120))
#' }
#' @importFrom rlang .env
#' @export
#' @author Codex
cd_mapbox <- function(cd = NULL, congress, state = NULL, cities = NULL,
                    zoom_to_cities = FALSE,
                    colors = c("#2166AC", "#D95F02", "#009E73")) {
  geography <- .cd_mapbox_geography(cd, state)
  if (missing(congress) || !is.numeric(congress) || !length(congress) ||
      anyNA(congress) || any(!is.finite(congress)) ||
      any(congress != trunc(congress)) || any(congress < 1 | congress > 120)) {
    cli::cli_abort("{.arg congress} must contain whole Congress numbers from 1 to 120.")
  }
  congress_ids <- unique(as.integer(congress))
  if (length(congress_ids) > 3L) {
    cli::cli_abort("Compare at most three Congresses in one map.")
  }
  if (!is.null(cities) && (!is.character(cities) || anyNA(cities) ||
      any(!nzchar(trimws(cities))))) {
    cli::cli_abort("{.arg cities} must contain one or two city names, or {.val NULL}.")
  }
  city_names <- trimws(cities)
  selected_cities <- city_names[!duplicated(tolower(city_names))]
  if (length(selected_cities) > 2L) {
    cli::cli_abort("Highlight at most two cities in one map.")
  }
  if (!is.logical(zoom_to_cities) || length(zoom_to_cities) != 1L || is.na(zoom_to_cities)) {
    cli::cli_abort("{.arg zoom_to_cities} must be {.val TRUE} or {.val FALSE}.")
  }
  if (zoom_to_cities && !length(selected_cities)) {
    cli::cli_abort("Select a city with {.arg cities} before using {.code zoom_to_cities = TRUE}.")
  }
  if (!is.character(colors) || length(colors) < length(congress_ids) || anyNA(colors)) {
    cli::cli_abort("Supply one color for each Congress with {.arg colors}.")
  }
  if (!requireNamespace("mapgl", quietly = TRUE)) {
    cli::cli_abort(c(
      "Interactive maps require {.pkg mapgl}.",
      "i" = "Install it with {.code install.packages(\"mapgl\")}."
    ))
  }
  token <- Sys.getenv("MAPBOX_PUBLIC_TOKEN")
  if (!startsWith(token, "pk.")) {
    cli::cli_abort(c(
      "Set {.envvar MAPBOX_PUBLIC_TOKEN} to a Mapbox public token.",
      "i" = "See {.code help(\"mapbox-setup\", package = \"fourthirtyfive\")} for setup."
    ))
  }

  district_layers <- lapply(congress_ids, function(congress_id) {
    district_input <- .cd_mapbox_boundaries(geography$state, congress_id, geography$cd)
    dplyr::mutate(
      district_input,
      label = glue::glue("{district_input$cd} \u2014 Congress {congress_id}")
    )
  })
  districts <- dplyr::bind_rows(district_layers)
  places <- if (length(selected_cities)) {
    .cd_mapbox_places(geography$state, selected_cities)
  } else NULL
  layer_colors <- colors[seq_along(congress_ids)]
  source_ids <- as.character(glue::glue("congress-{congress_ids}"))
  outline_widths <- if (length(congress_ids) == 1L) 2.5 else {
    seq(6, 2.5, length.out = length(congress_ids))
  }

  base_map <- mapgl::mapboxgl(
    style = mapgl::mapbox_style("streets"), projection = "mercator", height = 650,
    preserveDrawingBuffer = TRUE
  )
  filled_map <- purrr::reduce(seq_along(congress_ids), function(map, index) {
    source_id <- source_ids[[index]]
    map |>
      mapgl::add_source(id = source_id, data = district_layers[[index]]) |>
      mapgl::add_fill_layer(
        id = glue::glue("{source_id}-fill"), source = source_id,
        fill_color = layer_colors[[index]], fill_opacity = 0.08, popup = "label"
      )
  }, .init = base_map)
  outlined_map <- purrr::reduce(seq_along(congress_ids), function(map, index) {
    source_id <- source_ids[[index]]
    mapgl::add_line_layer(
      map, id = glue::glue("{source_id}-outline"), source = source_id,
      line_color = layer_colors[[index]], line_width = outline_widths[[index]],
      tooltip = "label"
    )
  }, .init = filled_map)
  district_map <- mapgl::add_legend(
    outlined_map, legend_title = if (is.null(cd)) geography$state else toupper(cd),
    values = glue::glue("Congress {congress_ids}"), colors = layer_colors,
    type = "categorical"
  )
  control_layers <- stats::setNames(lapply(source_ids, function(source_id) {
    as.character(glue::glue("{source_id}-{c('fill', 'outline')}"))
  }), as.character(glue::glue("Congress {congress_ids}")))

  city_map <- if (is.null(places)) district_map else {
    district_map |>
      mapgl::add_source(id = "city-boundaries", data = places) |>
      mapgl::add_fill_layer(
        id = "city-fills", source = "city-boundaries", fill_color = "#CC338B",
        fill_opacity = 0.08, popup = "NAME"
      ) |>
      mapgl::add_line_layer(
        id = "city-outlines", source = "city-boundaries",
        line_color = "#CC338B", line_width = 3, tooltip = "NAME"
      ) |>
      mapgl::add_legend(
        legend_title = "City boundaries (2026)", values = places$NAME,
        colors = rep("#CC338B", nrow(places)), type = "categorical",
        position = "bottom-left", add = TRUE
      )
  }
  if (!is.null(places)) control_layers[["Cities"]] <- c("city-fills", "city-outlines")
  initial_extent <- if (zoom_to_cities) places else districts
  city_map |>
    mapgl::add_layers_control(
      layers = control_layers, position = "top-right", collapsible = FALSE,
      margin_right = 50
    ) |>
    mapgl::fit_bounds(initial_extent, padding = 60) |>
    mapgl::add_navigation_control() |>
    mapgl::add_screenshot_control()
}

# Geography selection ----

.cd_mapbox_geography <- function(cd, state) {
  if (is.null(cd) == is.null(state)) {
    cli::cli_abort("Supply exactly one of {.arg cd} or {.arg state}.")
  }
  if (!is.null(cd)) {
    if (!is.character(cd) || length(cd) != 1L || is.na(cd) ||
        !grepl("^[A-Za-z]{2}-[0-9]{2}$", cd)) {
      cli::cli_abort("{.arg cd} must be one district code such as {.val TN-09}.")
    }
    state_code <- substr(toupper(cd), 1, 2)
  } else {
    state_code <- normalize_cd_states(state)
    if (length(state_code) != 1L) cli::cli_abort("Select one state per map.")
  }
  if (!state_code %in% datasets::state.abb) {
    cli::cli_abort("Select a U.S. state.")
  }
  if (state_code %in% c("AK", "HI")) {
    cli::cli_abort("Interactive geographic maps require unshifted boundaries; Alaska and Hawaii use package insets.")
  }
  list(state = state_code, cd = if (is.null(cd)) NULL else toupper(cd))
}

.cd_mapbox_boundaries <- function(state, congress, cd = NULL) {
  boundary_input <- if (state == "NC" && congress == 117L) {
    .cd_mapbox_nc117()
  } else {
    cd_boundaries(congress = congress, state = state, simplify = congress != 120L)
  }
  selected <- if (is.null(cd)) boundary_input else {
    dplyr::filter(boundary_input, .data$cd == .env$cd)
  }
  if (!nrow(selected) || anyDuplicated(selected$cd) ||
      (!is.null(cd) && nrow(selected) != 1L)) {
    cli::cli_abort("No unique district boundaries found for this selection in Congress {congress}.")
  }
  selected |>
    sf::st_make_valid() |>
    sf::st_transform(4326)
}

.cd_mapbox_nc117 <- function() {
  plan_url <- "https://www.ncleg.gov/Files/GIS/Plans_Main/Congress_2019/HB1029%203rd%20Edition%20-%20Shapefile.zip"
  plan_dir <- tempfile("nc-congress-117-")
  dir.create(plan_dir)
  on.exit(unlink(plan_dir, recursive = TRUE), add = TRUE)
  plan_zip <- file.path(plan_dir, "plan.zip")
  utils::download.file(plan_url, plan_zip, mode = "wb", quiet = TRUE)
  utils::unzip(plan_zip, exdir = plan_dir)
  plan_shp <- list.files(plan_dir, pattern = "\\.shp$", full.names = TRUE)
  sf::read_sf(plan_shp) |>
    dplyr::transmute(
      cd = as.character(glue::glue("NC-{stringr::str_pad(.data$DISTRICT, 2, pad = '0')}")),
      congress = 117L, year = 2021L, geometry = .data$geometry
    )
}

# Selected city outlines ----

.cd_mapbox_places <- function(state, cities) {
  places_raw <- tigris::places(state = state, year = 2026, cb = FALSE)
  incorporated <- dplyr::filter(places_raw, .data$MTFCC == "G4110")
  indices <- vapply(cities, function(city) {
    query <- tolower(trimws(city))
    exact <- which(tolower(incorporated$NAME) == query |
      tolower(incorporated$NAMELSAD) == query)
    matches <- if (length(exact)) exact else {
      which(startsWith(tolower(incorporated$NAME), query) |
        startsWith(tolower(incorporated$NAMELSAD), query))
    }
    candidates <- matches[!duplicated(incorporated$GEOID[matches])]
    if (length(candidates) != 1L) {
      cli::cli_abort("{.val {city}} must match exactly one incorporated city in {state}.")
    }
    candidates[[1L]]
  }, integer(1), USE.NAMES = FALSE)
  incorporated[unique(indices), ] |>
    dplyr::select("NAME", "geometry") |>
    sf::st_make_valid() |>
    sf::st_transform(4326)
}
