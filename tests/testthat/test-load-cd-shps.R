# Written by Codex
test_that("the 120th Congress updates nine states and preserves the 2025 map elsewhere", {
  local_mocked_bindings(.cd_map_cache = new.env(parent = emptyenv()))
  district_codes <- load_cd_info(year = 2025)$cd
  changed_states <- c("AL", "CA", "FL", "LA", "NC", "OH", "TN", "TX", "UT")
  state_codes <- tigris::fips_codes |>
    dplyr::distinct(.data$state, .data$state_code)
  polygons <- lapply(seq_along(district_codes), function(i) {
    x <- (i %% 30) * 100000
    y <- (i %/% 30) * 100000
    sf::st_polygon(list(rbind(
      c(x, y), c(x + 50000, y), c(x + 50000, y + 50000),
      c(x, y + 50000), c(x, y)
    )))
  })
  baseline_raw <- sf::st_sf(
    STATEFP = state_codes$state_code[
      match(substr(district_codes, 1, 2), state_codes$state)
    ],
    CD119FP = substr(district_codes, 4, 5),
    geometry = sf::st_sfc(polygons, crs = 5070)
  )
  updated <- substr(district_codes, 1, 2) %in% changed_states
  updated_raw <- baseline_raw[updated, ] |>
    dplyr::rename(CD120FP = "CD119FP")
  sf::st_geometry(updated_raw) <- sf::st_geometry(updated_raw) + c(1000, 2000)
  sf::st_crs(updated_raw) <- 5070
  insets <- baseline_raw[match(c("AK-01", "HI-01"), district_codes), ] |>
    dplyr::mutate(state_abbv = c("AK", "HI"))
  local_mocked_bindings(
    get_urbn_map = function(map, sf) insets,
    .package = "fourthirtyfive"
  )

  # A national 2026 request would include Missouri's superseded plan.
  # Require the loader to request only the nine redrawn states.
  local_mocked_bindings(
    congressional_districts = function(state = NULL, year, cb, resolution = NULL) {
      if (year == 2024L) {
        expect_true(cb)
        expect_equal(resolution, "20m")
        return(baseline_raw)
      }
      expect_equal(year, 2026L)
      expect_false(cb)
      expect_setequal(state, changed_states)
      updated_raw
    },
    .package = "tigris"
  )

  map_2025 <- load_cd_shps(year = 2025)
  map_2027 <- load_cd_shps(year = 2027)
  expect_equal(nrow(map_2027), 435L)
  expect_identical(map_2027$cd, sort(district_codes))
  expect_true(all(map_2027$year == 2027L))
  expect_true(all(map_2027$congress == 120L))
  expect_true(all(sf::st_is_valid(map_2027)))
  expect_false(any(sf::st_is_empty(map_2027)))
  old_geometry <- sf::st_geometry(map_2025)[match(map_2027$cd, map_2025$cd)]
  same_geometry <- vapply(seq_len(nrow(map_2027)), function(i) {
    identical(sf::st_geometry(map_2027)[[i]], old_geometry[[i]])
  }, logical(1))
  expect_identical(same_geometry, !updated)
  reader <- get_census_cd_sf
  local_mocked_bindings(get_census_cd_sf = function(congress) {
    if (congress == 120) stop("cache miss")
    reader(congress)
  })
  expect_identical(load_cd_shps(congress = 120), map_2027)

  map_lonlat <- load_cd_shps(year = 2027, epsg = 4326)
  expect_equal(sf::st_crs(map_lonlat)$epsg, 4326L)
  expect_identical(
    sf::st_as_binary(sf::st_geometry(map_lonlat)),
    sf::st_as_binary(sf::st_geometry(sf::st_transform(map_2027, 4326)))
  )
  stacked <- load_cd_shps(congress = c(119, 120))
  expect_equal(nrow(stacked), 870L)
  expect_equal(as.integer(table(stacked$congress)), c(435L, 435L))
  expect_error(load_cd_shps(year = 2027, cache = FALSE), "cache miss")
  expect_error(load_cd_shps(congress = 121), "greater than 120")
})

test_that("joint simplification preserves shared edges and Missouri exactly", {
  y <- seq(0, 100000, length.out = 501)
  edge <- cbind(50000 + sin(y / 5000) * 5000, y)
  left <- sf::st_polygon(list(rbind(c(0, 0), edge, c(0, 100000), c(0, 0))))
  right <- sf::st_polygon(list(rbind(
    edge[1, ], c(100000, 0), c(100000, 100000), edge[nrow(edge):1, ]
  )))
  missouri <- sf::st_polygon(list(rbind(
    c(150000, 0), c(200000, 0), c(200000, 50000), c(150000, 50000), c(150000, 0)
  )))
  original <- sf::st_sf(
    cd = c("AL-01", "AL-02", "MO-01"),
    geometry = sf::st_sfc(left, right, missouri, crs = 5070)
  )
  simplified <- simplify_cd_2027(original)
  expect_identical(simplified$cd, original$cd)
  expect_true(all(sf::st_is_valid(simplified)))
  expect_false(any(sf::st_is_empty(simplified)))
  expect_true(all(lengths(sf::st_overlaps(simplified)) == 0L))
  expect_identical(sf::st_geometry(simplified)[[3]], sf::st_geometry(original)[[3]])
  expect_lt(
    nrow(sf::st_coordinates(sf::st_cast(simplified, "MULTIPOLYGON"))),
    nrow(sf::st_coordinates(sf::st_cast(original, "MULTIPOLYGON"))) / 5
  )
  difference <- sf::st_sym_difference(
    sf::st_union(original[1:2, ]), sf::st_union(simplified[1:2, ])
  )
  expect_equal(sum(as.numeric(sf::st_area(difference))), 0, tolerance = 1e-6)
})
