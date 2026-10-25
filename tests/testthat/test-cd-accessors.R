# Written by Codex
test_that("bundled cd accessors return the requested datasets", {
  cases <- list(
    list(
      canonical = cd_names,
      alias = load_cd_info,
      earlier = getExportedValue("fourthirtyfive", "info_2005"),
      latest = getExportedValue("fourthirtyfive", "info_2027")
    ),
    list(
      canonical = cd_dotmap,
      alias = load_shp_dot,
      earlier = getExportedValue("fourthirtyfive", "shp_dot_2005"),
      latest = getExportedValue("fourthirtyfive", "shp_dot_2027")
    ),
    list(
      canonical = cd_hexmap,
      alias = load_shp_hex,
      earlier = getExportedValue("fourthirtyfive", "shp_hex_2005"),
      latest = getExportedValue("fourthirtyfive", "shp_hex_2027")
    )
  )

  for (case in cases) {
    stacked <- dplyr::bind_rows(case$earlier, case$latest)
    for (accessor in list(case$canonical, case$alias)) {
      expect_identical(accessor(year = 2027), case$latest)
      expect_identical(accessor(congress = 120), case$latest)
      expect_identical(accessor(2027), case$latest)
      expect_identical(accessor(year = c(2005, 2027)), stacked)
      expect_identical(accessor(congress = c(109, 120)), stacked)
      expect_identical(accessor(year = 2027, congress = 109), case$latest)
    }
  }
})

test_that("the boundary alias forwards every argument", {
  local_mocked_bindings(
    cd_boundaries = function(year = NULL, congress = NULL, epsg = 5070,
                             simplify = TRUE, cache = TRUE, state = NULL) {
      list(
        year = year,
        congress = congress,
        epsg = epsg,
        simplify = simplify,
        cache = cache,
        state = state
      )
    },
    .package = "fourthirtyfive"
  )

  requested <- list(
    year = c(2005, 2027),
    congress = c(109, 120),
    epsg = 4326,
    simplify = FALSE,
    cache = FALSE,
    state = c("California", "06")
  )
  expect_identical(do.call(load_cd_shps, requested), requested)
  expect_identical(
    load_cd_shps(2027, NULL, 4326, FALSE, FALSE, "CA"),
    list(
      year = 2027,
      congress = NULL,
      epsg = 4326,
      simplify = FALSE,
      cache = FALSE,
      state = "CA"
    )
  )
  expect_identical(
    load_cd_shps(),
    list(
      year = NULL,
      congress = NULL,
      epsg = 5070,
      simplify = TRUE,
      cache = TRUE,
      state = NULL
    )
  )
})
