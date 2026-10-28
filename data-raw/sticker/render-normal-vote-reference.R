# Written by Codex

# Normal vote sticker references ----
# Run from the package root after rebuilding data/normal_vote.rda.
# The 2025 datasets describe the 2024 election / 119th Congress map.

pkgload::load_all(quiet = TRUE)
library(ggplot2)

reference_dir <- file.path("data-raw", "sticker")
private_dir <- file.path("/private", "tmp", "fourthirtyfive-sticker")
dir.create(reference_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(private_dir, recursive = TRUE, showWarnings = FALSE)

# Normal vote hex cartogram ----
hex_normal_vote <- cd_hexmap(year = 2025) |>
  sf::st_make_valid() |>
  dplyr::left_join(
    cd_normal_vote(year = 2025) |>
      dplyr::select("cong", "cd", "normal_vote"),
    by = c("cong", "cd"), relationship = "one-to-one"
  ) |>
  dplyr::mutate(state = substr(.data$cd, 1, 2))

stopifnot(
  nrow(hex_normal_vote) == 435L,
  !anyDuplicated(hex_normal_vote$cd),
  all(hex_normal_vote$cong == 119L),
  is.numeric(hex_normal_vote$normal_vote),
  all(is.finite(hex_normal_vote$normal_vote)),
  any(hex_normal_vote$normal_vote < 0),
  any(hex_normal_vote$normal_vote > 0)
)

hex_normal_vote_plot <- ggplot2::ggplot(hex_normal_vote) +
  ggredist::geom_district(
    ggplot2::aes(group = cd, fill = normal_vote),
    color = "white", linewidth = 0.1
  ) +
  ggredist::geom_district(
    ggplot2::aes(group = state),
    fill = NA, color = "grey40", linewidth = 0.25, show.legend = FALSE
  ) +
  ggredist::scale_fill_party_c(
    name = "Normal vote", midpoint = 0, limits = c(-0.4, 0.4),
    labels = ggredist::label_party_margin(midpoint = 0)
  ) +
  ggplot2::coord_sf(datum = NA, expand = FALSE) +
  ggredist::theme_map(
    text = ggplot2::element_text(family = "sans", size = 11, color = "black"),
    legend.position = "none",
    plot.background = ggplot2::element_rect(fill = "white", color = NA),
    plot.margin = ggplot2::margin(20, 20, 20, 20)
  )

ggplot2::ggsave(
  file.path(reference_dir, "hex-normal-vote-2024.png"), hex_normal_vote_plot,
  width = 9, height = 6, units = "in", dpi = 200, device = ragg::agg_png
)

# Locator guide for the final logo color correction ----
utah_shapes <- dplyr::filter(hex_normal_vote, state == "UT")
utah_guide <- hex_normal_vote_plot +
  ggplot2::geom_sf(
    data = utah_shapes, fill = NA, color = "#00AA00", linewidth = 1.1
  ) +
  ggplot2::geom_sf_label(
    data = sf::st_sf(geometry = sf::st_centroid(sf::st_union(utah_shapes))),
    label = "UTAH", size = 3, color = "#006600", nudge_y = 180000
  )
ggplot2::ggsave(
  file.path(reference_dir, "hex-normal-vote-utah-guide.png"), utah_guide,
  width = 9, height = 6, units = "in", dpi = 200, device = ragg::agg_png
)

# Geographic district boundaries ----
# Keep downloaded cache data and token-bearing widget HTML outside the package.
sticker_cache <- file.path(private_dir, "tigris-cache")
dir.create(sticker_cache, recursive = TRUE, showWarnings = FALSE)
existing_cache <- path.expand("~/Library/Caches/tigris")
cached_baseline <- list.files(
  existing_cache, pattern = "^cb_2024_us_cd119_20m\\.", full.names = TRUE
)
missing_baseline <- cached_baseline[!file.exists(
  file.path(sticker_cache, basename(cached_baseline))
)]
invisible(file.copy(missing_baseline, sticker_cache, overwrite = FALSE))
Sys.setenv(TIGRIS_CACHE_DIR = sticker_cache)
options(tigris_use_cache = TRUE, timeout = 600)

district_map <- cd_boundaries(congress = 119, epsg = 4326, simplify = TRUE) |>
  dplyr::filter(!substr(.data$cd, 1, 2) %in% c("AK", "HI")) |>
  sf::st_make_valid()

stopifnot(
  nrow(district_map) == 432L,
  !anyDuplicated(district_map$cd),
  all(district_map$congress == 119L)
)

# Mapbox Streets reference ----
stopifnot(startsWith(Sys.getenv("MAPBOX_PUBLIC_TOKEN"), "pk."))

map_widget <- mapgl::mapboxgl(
  style = mapgl::mapbox_style("streets"),
  center = c(-97.5, 38.5), zoom = 3.5, projection = "mercator",
  width = 1800, height = 1200, preserveDrawingBuffer = TRUE
) |>
  mapgl::add_source(id = "districts-119", data = district_map) |>
  mapgl::add_fill_layer(
    id = "district-fill", source = "districts-119",
    fill_color = "#193A52", fill_opacity = 0.025
  ) |>
  mapgl::add_line_layer(
    id = "district-boundaries", source = "districts-119",
    line_color = "#193A52", line_width = 1.6, line_opacity = 0.9
  ) |>
  mapgl::fit_bounds(c(-125, 24, -66.5, 50), padding = 55, animate = FALSE)

widget_html <- file.path(private_dir, "mapbox-2024.html")
framed_widget <- htmlwidgets::prependContent(
  map_widget,
  htmltools::tags$style(
    "html, body { margin: 0 !important; padding: 0 !important; }",
    "#htmlwidget_container { position: absolute; left: 0; top: 0; }"
  )
)
htmlwidgets::saveWidget(
  framed_widget, widget_html, selfcontained = TRUE,
  title = "2024 election districts on Mapbox Streets"
)

webshot2::webshot(
  widget_html, file.path(reference_dir, "mapbox-2024.png"),
  vwidth = 1800, vheight = 1200, cliprect = "viewport", delay = 15,
  quiet = TRUE
)

message(glue::glue(
  "Saved 435 normal vote districts and the 119th Congress Mapbox reference in {reference_dir}."
))
