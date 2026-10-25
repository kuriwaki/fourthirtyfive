# Written by Codex

# District boundaries ----
# Return one district in longitude/latitude for a geographic basemap.
# The package's Alaska/Hawaii insets are excluded from this example.
get_cd_geometry <- function(cd, congress) {
  stopifnot(
    is.character(cd), length(cd) == 1L, !is.na(cd),
    grepl("^[A-Z]{2}-[0-9]{2}$", cd),
    is.numeric(congress), length(congress) == 1L, !is.na(congress),
    congress == as.integer(congress), congress >= 1, congress <= 120
  )

  if (substr(cd, 1, 2) %in% c("AK", "HI")) {
    stop("Use original, unshifted boundaries for Alaska and Hawaii; the package uses map insets.", call. = FALSE)
  }

  if (substr(cd, 1, 2) == "NC" && congress == 117) {
    # Census's 2021 files retain the 116th map. Use NC's actual 2020 plan.
    # Source: https://www.ncleg.gov/Redistricting (Congress, enacted 2019).
    plan_url <- paste(
      "https://www.ncleg.gov/Files/GIS/Plans_Main/Congress_2019/",
      "HB1029%203rd%20Edition%20-%20Shapefile.zip",
      sep = ""
    )
    plan_dir <- tempfile("nc-congress-117-")
    dir.create(plan_dir)
    on.exit(unlink(plan_dir, recursive = TRUE), add = TRUE)
    plan_zip <- file.path(plan_dir, "plan.zip")
    utils::download.file(plan_url, plan_zip, mode = "wb", quiet = TRUE)
    utils::unzip(plan_zip, exdir = plan_dir)
    plan_shp <- list.files(plan_dir, pattern = "\\.shp$", full.names = TRUE)
    district_sf <- sf::read_sf(plan_shp) |>
      dplyr::transmute(
        cd = glue::glue("NC-{stringr::str_pad(DISTRICT, 2, pad = '0')}"),
        congress = .env$congress,
        year = 2021L,
        geometry
      ) |>
      dplyr::filter(.data$cd == .env$cd)
  } else {
    # Keep the loader's default CRS; filter before converting to longitude/latitude.
    district_sf <- fourthirtyfive::load_cd_shps(
      congress = congress, state = substr(cd, 1, 2), simplify = congress != 120
    ) |>
      dplyr::filter(.data$cd == .env$cd)
  }

  if (nrow(district_sf) != 1L) {
    stop(glue::glue("Expected one district for {cd} in Congress {congress}; found {nrow(district_sf)}."), call. = FALSE)
  }

  district_sf |>
    sf::st_make_valid() |>
    sf::st_transform(4326)
}

# Mapbox view ----
# Requires mapgl and a MAPBOX_PUBLIC_TOKEN environment variable.
view_mapbox <- function(cd, congress, colors = c("#2166AC", "#D95F02", "#009E73")) {
  stopifnot(is.numeric(congress), length(congress) > 0L, !anyNA(congress))
  congress_ids <- unique(congress)
  if (length(colors) < length(congress_ids) || anyNA(colors)) {
    stop("Supply one color for each Congress.", call. = FALSE)
  }
  layer_colors <- colors[seq_along(congress_ids)]
  source_ids <- glue::glue("district-{congress_ids}")
  # Draw later outlines more narrowly so coincident boundaries remain visible.
  outline_widths <- if (length(congress_ids) > 2L) {
    seq(6, 2.5, length.out = length(congress_ids))
  } else {
    rep(2.5, length(congress_ids))
  }
  district_layers <- purrr::map(congress_ids, function(congress_id) {
    get_cd_geometry(cd, congress_id) |>
      dplyr::mutate(label = glue::glue("{cd} — Congress {congress_id}"))
  })
  districts <- dplyr::bind_rows(district_layers)

  base_map <- mapgl::mapboxgl(
    style = mapgl::mapbox_style("streets"),
    projection = "mercator",
    height = 650
  )
  add_district_fill <- function(map, index) {
    source_id <- source_ids[[index]]
    map |>
      mapgl::add_source(id = source_id, data = district_layers[[index]]) |>
      mapgl::add_fill_layer(
        id = glue::glue("{source_id}-fill"), source = source_id,
        fill_color = layer_colors[[index]], fill_opacity = 0.2,
        popup = "label"
      )
  }
  filled_map <- purrr::reduce(seq_along(congress_ids), add_district_fill, .init = base_map)
  # Keep every outline above the fills, including those added later.
  overlay_map <- purrr::reduce(seq_along(congress_ids), function(map, index) {
    source_id <- source_ids[[index]]
    map |>
      mapgl::add_line_layer(
        id = glue::glue("{source_id}-outline"), source = source_id,
        line_color = layer_colors[[index]], line_width = outline_widths[[index]]
      )
  }, .init = filled_map)

  overlay_map |>
    mapgl::add_legend(
      legend_title = cd,
      values = glue::glue("Congress {congress_ids}"),
      colors = layer_colors,
      type = "categorical"
    ) |>
    mapgl::fit_bounds(districts, padding = 60) |>
    mapgl::add_navigation_control()
}

# Check 2027 city descriptions ----
# Blue: one district. Pink: highlighted places. Gray: other places.
# By default show places in and around the district's map extent. Supply cities to select
# specific places, including those outside the district; hover for their names.
view_cd_2027 <- function(cd, cities = NULL, highlight = NULL, zoom_to_cities = FALSE) {
  stopifnot(is.character(cd), length(cd) == 1L, !is.na(cd), grepl("^[A-Z]{2}-[0-9]{2}$", cd))
  state <- substr(cd, 1, 2)
  stopifnot(state %in% c("AL", "CA", "FL", "LA", "NC", "OH", "TN", "TX", "UT"))
  district <- get_cd_geometry(cd, congress = 120)
  places_raw <- tigris::places(state = state, year = 2026, cb = FALSE)
  resolve_names <- function(requested) {
    available <- unique(places_raw$NAME)
    vapply(requested, function(name) {
      matches <- available[tolower(available) == tolower(name)]
      if (!length(matches)) matches <- available[startsWith(tolower(available), tolower(name))]
      if (length(matches) != 1L) {
        stop(glue::glue("'{name}' must match one Census place name in {state}."), call. = FALSE)
      }
      matches
    }, character(1), USE.NAMES = FALSE)
  }
  city_names <- resolve_names(cities)
  highlighted_names <- resolve_names(highlight)
  places_input <- if (is.null(cities)) places_raw else {
    dplyr::filter(places_raw, .data$NAME %in% c(city_names, highlighted_names))
  }
  places_projected <- places_input |>
    dplyr::select(NAME, geometry) |>
    sf::st_transform(5070) |>
    sf::st_make_valid()
  nearby <- if (is.null(cities)) {
    view_area <- sf::st_as_sfc(sf::st_bbox(sf::st_transform(district, 5070))) |>
      sf::st_buffer(10000)
    lengths(sf::st_intersects(places_projected, view_area)) > 0L
  } else {
    places_projected$NAME %in% city_names
  }
  places <- places_projected[nearby | places_projected$NAME %in% highlighted_names, ] |>
    dplyr::transmute(
      NAME, city_color = dplyr::if_else(.data$NAME %in% highlighted_names, "#CC338B", "#555555"),
      geometry
    ) |>
    sf::st_transform(4326)

  city_map <- view_mapbox(cd, congress = 120) |>
    mapgl::add_source(id = "city-boundaries", data = places) |>
    mapgl::add_fill_layer(
      id = "city-fills", source = "city-boundaries",
      fill_color = mapgl::get_column("city_color"), fill_opacity = 0.08,
      popup = "NAME"
    ) |>
    mapgl::add_line_layer(
      id = "city-outlines", source = "city-boundaries",
      line_color = mapgl::get_column("city_color"), line_width = 2,
      tooltip = "NAME"
    ) |>
    mapgl::add_legend(
      legend_title = "City boundaries", values = c("Highlighted places", "Other places"),
      colors = c("#CC338B", "#555555"), type = "categorical",
      position = "bottom-left", add = TRUE
    )
  focus_places <- if (is.null(cities) && length(highlighted_names)) {
    dplyr::filter(places, .data$NAME %in% highlighted_names)
  } else places
  if (isTRUE(zoom_to_cities) && nrow(focus_places)) mapgl::fit_bounds(city_map, focus_places, padding = 60) else city_map
}

# Retain the original Utah view and initial zoom ----
view_utah_2027 <- function(cd, zoom_to_cities = TRUE) {
  stopifnot(is.character(cd), length(cd) == 1L, !is.na(cd), grepl("^UT-0[1-4]$", cd))
  view_cd_2027(cd, cities = c(
    "Salt Lake City", "North Salt Lake", "South Salt Lake", "West Valley City",
    "West Jordan", "South Jordan", "Millcreek", "Holladay", "Cottonwood Heights",
    "Sandy", "Draper", "Lehi", "Orem", "Provo"
  ), highlight = "Salt Lake City", zoom_to_cities = zoom_to_cities)
}

# Examples: run one at a time in the RStudio console ----
# options(tigris_use_cache = TRUE)
# view_mapbox("FL-05", congress = 113)
# view_mapbox("FL-05", congress = 115)
# view_mapbox("NC-13", congress = 113)
# view_mapbox("NC-13", congress = 117)
# view_mapbox("FL-05", congress = c(113, 115))
# view_mapbox("FL-10", congress = c(113, 114, 115))
# view_mapbox("NC-13", congress = c(113, 115))
# view_mapbox("NC-13", congress = c(115, 117))
# district_sf <- get_cd_geometry("NC-13", congress = 117)
# view_utah_2027("UT-03")
# view_utah_2027("UT-04")
# view_utah_2027("UT-01") # Salt Lake City proper is inside this district.
# view_utah_2027("UT-03", zoom_to_cities = FALSE) # Whole district, including St. George.
# view_cd_2027("NC-01")
# view_cd_2027("NC-03", highlight = c("Greenville", "Jacksonville"))
# view_cd_2027("OH-13", cities = c("Akron", "Canton"), highlight = c("Akron", "Canton"), zoom_to_cities = TRUE)
# view_cd_2027("OH-10", highlight = c("Dayton", "Middletown"))
# view_cd_2027("OH-15", highlight = "Columbus", zoom_to_cities = TRUE)
# view_cd_2027("TN-04", highlight = c("Nashville", "Murfreesboro"))
