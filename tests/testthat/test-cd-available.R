# Written by Codex

test_that("availability reports each bundled product without fetching maps", {
  local_mocked_bindings(
    get_lewis_sf = function(...) stop("Unexpected map retrieval"),
    get_census_cd_sf = function(...) stop("Unexpected map retrieval")
  )

  result <- withVisible(cd_available(quiet = TRUE))
  available <- result$value
  expect_false(result$visible)
  expect_s3_class(available, "tbl_df")
  expect_named(available, c("accessor", "year", "congress", "source"))
  expect_setequal(unique(available$accessor), c(
    "cd_boundaries", "cd_dotmap", "cd_hexmap", "cd_names"
  ))
  expect_identical(anyDuplicated(available[c("accessor", "congress")]), 0L)
  expect_identical(available$year, cong_to_firstyear(available$congress))

  boundaries <- available[available$accessor == "cd_boundaries", ]
  expect_identical(boundaries$congress, seq_len(120L))
  expect_match(boundaries$source[boundaries$congress == 1L], "Lewis")
  expect_match(boundaries$source[boundaries$congress == 113L], "Census")
  expect_match(boundaries$source[boundaries$congress == 120L], "mixed")

  index_items <- utils::data(package = "fourthirtyfive")$results[, "Item"]
  prefixes <- c(cd_dotmap = "shp_dot_", cd_hexmap = "shp_hex_", cd_names = "info_")
  for (accessor in names(prefixes)) {
    bundled_items <- index_items[startsWith(index_items, prefixes[[accessor]])]
    bundled_years <- as.integer(sub(".*_([0-9]{4}).*", "\\1", bundled_items))
    expect_identical(
      available$year[available$accessor == accessor],
      sort(unique(bundled_years))
    )
  }
  historical_hexes <- available[
    available$accessor == "cd_hexmap" & available$year <= 2011L,
  ]
  expect_true(all(grepl("2009.*reused", historical_hexes$source)))
})

test_that("availability parses decorated data index entries and ignores nonyear items", {
  items <- c(
    "shp_dot_2027 (shp_dot)", "shp_dot_2005", "shp_dot_2027",
    "shp_dot_notes", "shp_dot_2025_extra", "shp_hex_2027", "shp_states"
  )
  expect_identical(.cd_available_years(items, "shp_dot_"), c(2005L, 2027L))
  expect_identical(.cd_available_years(character(), "shp_dot_"), integer())
  expect_identical(.cd_available_range(c(2005L, 2009L), step = 2L), "2005, 2009")
})

test_that("availability supports silent programmatic use and explains year semantics", {
  expect_silent(cd_available(quiet = TRUE))
  guide <- capture.output(cd_available(), type = "message")
  expect_match(paste(guide, collapse = "\n"), "Years refer to the start of a Congress")
  expect_match(paste(guide, collapse = "\n"), "cd_boundaries")
  expect_error(cd_available(quiet = NA), "quiet.*TRUE.*FALSE")
  expect_error(cd_available(quiet = 1), "quiet.*TRUE.*FALSE")
})
