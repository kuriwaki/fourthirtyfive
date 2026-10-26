# Written by Codex

# Repair narrow gaps in district cartograms before bundling ----
clean_hexmap <- function(hexmap) {
  state_union <- function(x) {
    x |>
      sf::st_make_valid() |>
      dplyr::group_by(state = substr(cd, 1, 2)) |>
      dplyr::summarize(.groups = "drop")
  }
  has_holes <- function(geometry) {
    vapply(geometry, function(polygon) {
      parts <- if (inherits(polygon, "POLYGON")) list(polygon) else polygon
      any(vapply(parts, length, integer(1)) > 1L)
    }, logical(1))
  }

  stopifnot(
    inherits(hexmap, "sf"), !sf::st_is_longlat(hexmap),
    !anyDuplicated(hexmap$cd), !any(sf::st_is_empty(hexmap))
  )
  original_states <- state_union(hexmap)
  invalid_states <- substr(hexmap$cd[!sf::st_is_valid(hexmap)], 1, 2)
  affected_states <- union(
    original_states$state[has_holes(sf::st_geometry(original_states))],
    invalid_states
  )
  if (!length(affected_states)) return(hexmap)

  # Mapshaper cleans shared coverage, preserving districts inside other districts.
  # The largest observed gap is 58 million square map meters; cap filling at 100M.
  # Work state by state so gaps between separate state cartograms stay open.
  result_geometry <- sf::st_geometry(hexmap)
  for (state in affected_states) {
    affected_rows <- which(substr(hexmap$cd, 1, 2) == state)
    source_json <- geojsonsf::sf_geojson(hexmap[affected_rows, ], simplify = FALSE)
    cleaned_json <- rmapshaper::apply_mapshaper_commands(
      source_json, "-clean gap-fill-area=100000000"
    )
    cleaned <- geojsonsf::geojson_sf(cleaned_json)
    stopifnot(
      !anyDuplicated(cleaned$cd),
      setequal(cleaned$cd, hexmap$cd[affected_rows])
    )
    # GeoJSON assumes longitude/latitude; retain the source coordinate system.
    ordered_geometry <- sf::st_geometry(cleaned)[match(hexmap$cd[affected_rows], cleaned$cd)]
    repaired_geometry <- sf::st_sfc(
      lapply(ordered_geometry, identity), crs = sf::st_crs(hexmap)
    ) |>
      sf::st_cast("MULTIPOLYGON")
    result_geometry[affected_rows] <- repaired_geometry
  }
  result <- sf::st_set_geometry(hexmap, result_geometry)
  stopifnot(
    all(sf::st_is_valid(result)), !any(sf::st_is_empty(result)),
    !any(has_holes(sf::st_geometry(state_union(result))))
  )
  result
}
