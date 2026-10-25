# Written by Codex

cd_mapbox_test_boundaries <- function(state = "TN", congress = 119L, cd = NULL) {
  offset <- (congress - 119) * 0.03
  polygons <- lapply(seq_len(2L), function(index) {
    x <- -90 + (index - 1) * 0.2 + offset
    sf::st_polygon(list(rbind(
      c(x, 35), c(x + 0.15, 35), c(x + 0.15, 35.15),
      c(x, 35.15), c(x, 35)
    )))
  })
  boundaries <- sf::st_sf(
    cd = as.character(glue::glue("{state}-{c('01', '02')}")),
    congress = rep(as.integer(congress), 2),
    geometry = sf::st_sfc(polygons, crs = 4326)
  )
  if (is.null(cd)) boundaries else boundaries[boundaries$cd == cd, ]
}

cd_mapbox_test_cities <- function(names = c("Memphis", "Knoxville")) {
  polygons <- lapply(seq_along(names), function(index) {
    x <- -89.95 + index * 0.03
    sf::st_polygon(list(rbind(
      c(x, 35.02), c(x + 0.01, 35.02), c(x + 0.01, 35.03),
      c(x, 35.03), c(x, 35.02)
    )))
  })
  sf::st_sf(NAME = names, geometry = sf::st_sfc(polygons, crs = 4326))
}

cd_mapbox_test_setup <- function(.env = parent.frame()) {
  skip_if_not_installed("mapgl", minimum_version = "0.5.0")
  withr::local_envvar(c(MAPBOX_PUBLIC_TOKEN = "pk.fixture"), .local_envir = .env)
  local_mocked_bindings(
    mapboxgl = function(...) {
      arguments <- list(...)
      mapgl::maplibre(
        style = "https://demotiles.maplibre.org/style.json", height = arguments$height
      )
    },
    .package = "mapgl", .env = .env
  )
}

test_that("statewide views compare unique Congresses without fetching cities by default", {
  cd_mapbox_test_setup()
  requests <- list()
  local_mocked_bindings(
    .cd_mapbox_boundaries = function(state, congress, cd = NULL) {
      requests[[length(requests) + 1L]] <<- list(state = state, congress = congress, cd = cd)
      cd_mapbox_test_boundaries(state, congress, cd)
    },
    .cd_mapbox_places = function(...) stop("Unexpected city retrieval")
  )

  view <- cd_mapbox(state = "Tennessee", congress = c(119, 120, 119))

  expect_length(requests, 2L)
  expect_identical(requests[[1L]], list(state = "TN", congress = 119L, cd = NULL))
  expect_identical(requests[[2L]], list(state = "TN", congress = 120L, cd = NULL))
  expect_length(view$x$sources, 2L)
  for (source in view$x$sources) {
    source_data <- sf::st_read(source$data, quiet = TRUE)
    expect_setequal(source_data$cd, c("TN-01", "TN-02"))
  }
  layer_types <- vapply(view$x$layers, function(layer) layer$type, character(1))
  expect_identical(layer_types, c("fill", "fill", "line", "line"))
  widths <- vapply(view$x$layers[layer_types == "line"], function(layer) {
    layer$paint[["line-width"]]
  }, numeric(1))
  expect_true(all(diff(widths) < 0))
  expected_extent <- dplyr::bind_rows(
    cd_mapbox_test_boundaries(congress = 119L),
    cd_mapbox_test_boundaries(congress = 120L)
  )
  expect_equal(view$x$fitBounds$bounds, as.vector(sf::st_bbox(expected_extent)))
})

test_that("selected cities stay magenta above three ordered Congress outlines", {
  cd_mapbox_test_setup()
  requested_cities <- NULL
  places <- cd_mapbox_test_cities()
  local_mocked_bindings(
    .cd_mapbox_boundaries = cd_mapbox_test_boundaries,
    .cd_mapbox_places = function(state, cities) {
      expect_identical(state, "TN")
      requested_cities <<- cities
      places[places$NAME %in% cities, ]
    }
  )

  view <- cd_mapbox(
    state = "TN", congress = 118:120, cities = c("Memphis", "Knoxville"),
    zoom_to_cities = TRUE
  )

  expect_identical(requested_cities, c("Memphis", "Knoxville"))
  city_source <- Filter(function(source) source$id == "city-boundaries", view$x$sources)
  expect_length(city_source, 1L)
  city_data <- sf::st_read(city_source[[1L]]$data, quiet = TRUE)
  expect_setequal(city_data$NAME, c("Memphis", "Knoxville"))
  expect_equal(nrow(city_data), 2L)
  city_layers <- Filter(function(layer) layer$source == "city-boundaries", view$x$layers)
  expect_identical(vapply(city_layers, function(layer) layer$type, character(1)), c("fill", "line"))
  expect_identical(city_layers[[1L]]$paint[["fill-color"]], "#CC338B")
  expect_identical(city_layers[[2L]]$paint[["line-color"]], "#CC338B")

  district_layers <- Filter(function(layer) layer$source != "city-boundaries", view$x$layers)
  expect_identical(
    vapply(district_layers, function(layer) layer$type, character(1)),
    c("fill", "fill", "fill", "line", "line", "line")
  )
  widths <- vapply(district_layers[4:6], function(layer) layer$paint[["line-width"]], numeric(1))
  expect_true(all(diff(widths) < 0))
  expect_identical(tail(view$x$layers, 1L)[[1L]]$id, "city-outlines")
  expect_equal(view$x$fitBounds$bounds, as.vector(sf::st_bbox(places)))

  district_view <- cd_mapbox(state = "TN", congress = c(119, 120), cities = "Memphis")
  expected_extent <- dplyr::bind_rows(
    cd_mapbox_test_boundaries(congress = 119L),
    cd_mapbox_test_boundaries(congress = 120L)
  )
  expect_equal(district_view$x$fitBounds$bounds, as.vector(sf::st_bbox(expected_extent)))
})

test_that("invalid selections and missing public credentials fail before retrieval", {
  cd_mapbox_test_setup()
  local_mocked_bindings(
    .cd_mapbox_boundaries = function(...) stop("Unexpected boundary retrieval"),
    .cd_mapbox_places = function(...) stop("Unexpected city retrieval")
  )

  expect_error(cd_mapbox(state = "TN", congress = 117:120), "three Congresses")
  expect_error(cd_mapbox(state = "TN", congress = 119.5), "whole Congress")
  expect_error(cd_mapbox(state = "TN", congress = c(119, NA)), "whole Congress")
  expect_error(cd_mapbox(state = "TN", congress = 121), "whole Congress")
  expect_error(cd_mapbox(state = "TN", congress = 119, cities = c("A", "B", "C")), "two cities")
  expect_error(cd_mapbox(state = "TN", congress = 119, zoom_to_cities = TRUE), "Select a city")
  expect_error(cd_mapbox(congress = 119), "exactly one")
  expect_error(cd_mapbox("TN-01", congress = 119, state = "TN"), "exactly one")
  expect_error(cd_mapbox("TN-1", congress = 119), "district code")
  expect_error(cd_mapbox(state = c("TN", "NC"), congress = 119), "one state")
  expect_error(cd_mapbox(state = "AK", congress = 119), "insets")
  expect_error(cd_mapbox("HI-01", congress = 119), "insets")

  withr::local_envvar(c(MAPBOX_PUBLIC_TOKEN = ""))
  expect_error(cd_mapbox(state = "TN", congress = 119), "Mapbox public token")
})

test_that("city resolution matches incorporated places and rejects ambiguity and CDPs", {
  fixture <- cd_mapbox_test_cities(c("Memphis", "Memphis", "Memphisville", "Knoxville", "Cedar Grove"))
  places <- dplyr::mutate(
    fixture,
    NAMELSAD = c("Memphis city", "Memphis CDP", "Memphisville town", "Knoxville city", "Cedar Grove CDP"),
    MTFCC = c("G4110", "G4210", "G4110", "G4110", "G4210"),
    GEOID = c("4700001", "4700002", "4700003", "4700004", "4700005")
  )
  local_mocked_bindings(
    places = function(state, year, cb) {
      expect_identical(state, "TN")
      expect_false(cb)
      places
    },
    .package = "tigris"
  )

  matched <- .cd_mapbox_places("TN", c("mEmPhIs", "Knoxville city"))
  expect_setequal(matched$NAME, c("Memphis", "Knoxville"))
  expect_equal(nrow(matched), 2L)
  expect_identical(sf::st_crs(matched)$epsg, 4326L)
  expect_error(.cd_mapbox_places("TN", "Mem"), "exactly one incorporated city")
  expect_error(.cd_mapbox_places("TN", "Cedar Grove"), "exactly one incorporated city")
  expect_error(.cd_mapbox_places("TN", "Not a city"), "exactly one incorporated city")
})

test_that("the NC 117th plan supports statewide and individual district views", {
  nc_plan <- sf::st_transform(cd_mapbox_test_boundaries("NC", 117L), 5070)
  local_mocked_bindings(
    .cd_mapbox_nc117 = function() nc_plan,
    cd_boundaries = function(...) stop("Unexpected Census retrieval for NC 117")
  )

  statewide <- .cd_mapbox_boundaries("NC", 117L)
  district <- .cd_mapbox_boundaries("NC", 117L, "NC-02")
  expect_setequal(statewide$cd, c("NC-01", "NC-02"))
  expect_identical(district$cd, "NC-02")
  expect_identical(sf::st_crs(statewide)$epsg, 4326L)
  expect_identical(sf::st_crs(district)$epsg, 4326L)
  expect_error(.cd_mapbox_boundaries("NC", 117L, "NC-99"), "No unique district")
})
