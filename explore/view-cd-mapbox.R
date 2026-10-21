# Written by Codex

# District boundaries ----
# Return one district in longitude/latitude for a geographic basemap.
# The package's Alaska/Hawaii insets are excluded from this example.
get_cd_geometry <- function(cd, congress) {
  stopifnot(
    is.character(cd), length(cd) == 1L, !is.na(cd),
    grepl("^[A-Z]{2}-[0-9]{2}$", cd),
    is.numeric(congress), length(congress) == 1L, !is.na(congress),
    congress == as.integer(congress), congress >= 1, congress <= 119
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
    district_sf <- fourthirtyfive::load_cd_shps(congress = congress) |>
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
