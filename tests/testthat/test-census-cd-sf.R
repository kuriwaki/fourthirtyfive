# Written by Codex
test_that("the shared Census reader handles district fields for Congresses 113 through 119", {
  square <- sf::st_polygon(list(rbind(c(0, 0), c(100, 0), c(100, 100), c(0, 100), c(0, 0))))
  for (congress in 113:119) {
    attributes <- data.frame(STATEFP = c("02", "06", "29"), district = c("00", "01", "01"))
    field_congress <- if (congress == 117) 116 else congress
    names(attributes)[2] <- stringr::str_glue("CD{field_congress}FP")
    raw <- sf::st_sf(attributes, geometry = sf::st_sfc(rep(list(square), 3), crs = 5070))
    expected_year <- if (congress == 119) 2024L else cong_to_firstyear(congress)
    local_mocked_bindings(
      congressional_districts = function(state, year, cb, resolution) {
        expect_null(state)
        expect_equal(year, expected_year)
        expect_true(cb)
        expect_equal(resolution, "20m")
        raw
      },
      .package = "tigris"
    )
    normalized <- get_census_cd_sf(congress)
    expect_identical(normalized$cd, c("AK-01", "CA-01", "MO-01"))
  }
})

test_that("2027 reports an outdated loaded tigris before downloading", {
  old_session_reader <- get_census_cd_sf
  environment(old_session_reader) <- list2env(
    list(getNamespaceVersion = function(package) "2.2.1"),
    parent = environment(get_census_cd_sf)
  )
  local_mocked_bindings(
    congressional_districts = function(...) stop("Download should not be reached"),
    .package = "tigris"
  )
  expect_error(
    old_session_reader(120L),
    "this R session has 2.2.1 loaded.*restart R"
  )
})
