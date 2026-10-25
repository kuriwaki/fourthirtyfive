# Written by Codex

test_that("one stacked PVI dataset exposes the compact public schema", {
  index_items <- utils::data(package = "fourthirtyfive")$results[, "Item"]
  item_names <- sub("[[:space:]]+\\(.*\\)$", "", index_items)
  expect_identical(item_names[grepl("^pvi($|_)", item_names)], "pvi")

  data_env <- new.env(parent = emptyenv())
  utils::data(list = "pvi", package = "fourthirtyfive", envir = data_env)
  stacked <- get("pvi", envir = data_env, inherits = FALSE)
  expect_s3_class(stacked, "tbl_df")
  expect_named(stacked, c(
    "cong", "election_year", "geography", "state", "cd", "pvi", "status", "accessed"
  ))
  expect_identical(nrow(stacked), (435L + 51L) * 15L)
  expect_setequal(stacked$geography, c("district", "state"))
  expect_identical(cd_pvi(), stacked[stacked$geography == "district", ])
  expect_identical(
    cd_pvi(geography = "state"),
    stacked[stacked$geography == "state", ]
  )
})

test_that("source data contains one PVI file and no yearly PVI files", {
  source_data_dir <- testthat::test_path("..", "..", "data")
  skip_if_not(dir.exists(source_data_dir), "Source data files are absent in installed-package tests.")
  expect_identical(
    list.files(source_data_dir, pattern = "^pvi(_[0-9]{4})?\\.rda$"),
    "pvi.rda"
  )
  data_env <- new.env(parent = emptyenv())
  expect_identical(load(file.path(source_data_dir, "pvi.rda"), envir = data_env), "pvi")
})

test_that("PVI tables preserve election years, identifiers, and public-source gaps", {
  districts <- cd_pvi()
  states <- cd_pvi(geography = "state")
  expect_s3_class(districts, "tbl_df")
  expect_identical(sort(unique(districts$cong)), 106:120)
  expect_identical(nrow(districts), 435L * 15L)
  expect_identical(nrow(states), 51L * 15L)
  expect_true(all(districts$election_year == cong_to_firstyear(districts$cong) - 1L))
  expect_identical(anyDuplicated(districts[c("cong", "cd")]), 0L)
  expect_identical(anyDuplicated(states[c("cong", "state")]), 0L)
  expect_true(all(is.na(states$cd)))
  expect_true(all(grepl("^[A-Z]{2}-[0-9]{2}$", districts$cd)))
  expect_false(any(grepl("-00$", districts$cd)))
  expect_true(all(districts$status %in% c("archive", "unchanged", "unavailable")))
  expect_identical(is.na(districts$pvi), districts$status == "unavailable")
  expect_identical(is.na(states$pvi), states$status == "unavailable")
  expect_identical(is.na(districts$accessed), districts$status == "unavailable")
  expect_identical(is.na(states$accessed), states$status == "unavailable")
  expect_true(any(districts$status == "unavailable"))
  expect_true(any(districts$status == "unchanged"))
  expect_true(any(districts$status == "archive"))
})

test_that("PVI selection follows existing year and Congress conventions", {
  recent <- cd_pvi(year = 2027)
  expect_identical(recent, cd_pvi(congress = 120))
  expect_identical(recent, cd_pvi(year = 2027, congress = 106))
  expect_identical(recent, cd_pvi(year = c(2027, 2027)))
  expect_identical(
    cd_pvi(year = c(2027, 1999)),
    dplyr::bind_rows(recent, cd_pvi(year = 1999))
  )
  expect_identical(
    cd_pvi(congress = c(120, 106), geography = "state"),
    dplyr::bind_rows(
      cd_pvi(year = 2027, geography = "state"),
      cd_pvi(year = 1999, geography = "state")
    )
  )
})

test_that("historical PVI reuse and current Missouri maps are preserved", {
  earliest <- cd_pvi(year = 1999)
  expect_true(all(earliest$election_year == 1998L))
  expect_true(all(earliest$status[!earliest$state %in% c("NC", "VA")] == "unchanged"))
  expect_true(all(is.na(earliest$pvi[earliest$state %in% c("NC", "VA")])))
  expect_true(all(!is.na(earliest$pvi[!earliest$state %in% c("NC", "VA")])))

  post_2020 <- cd_pvi(year = 2023)
  expect_false(anyNA(post_2020$pvi))
  expect_identical(post_2020$pvi[post_2020$cd == "CA-12"], "D+40")
  expect_identical(post_2020$pvi[post_2020$cd == "AL-04"], "R+33")
  expect_identical(post_2020$pvi[post_2020$cd == "ID-02"], "R+15")
  state_2023 <- cd_pvi(year = 2023, geography = "state")
  expect_identical(state_2023$pvi[state_2023$state == "AZ"], "R+2")
  expect_identical(state_2023$pvi[state_2023$state == "AK"], "R+8")

  current <- cd_pvi(year = 2027)
  expect_false(anyNA(current$pvi))
  expect_identical(current$pvi[current$cd == "MO-05"], "D+12")
  expect_identical(current$pvi[current$cd == "MO-02"], "R+4")
})

test_that("PVI arguments reject ambiguous and unsupported selections", {
  for (year in list(1998, 2028, 2025.5, NA_real_, Inf, "2027", TRUE, numeric())) {
    expect_error(cd_pvi(year = year), "year")
  }
  expect_error(cd_pvi(year = 2026), "odd Congress start years")
  for (congress in list(105, 121, 119.5, NA_real_, Inf, "120", TRUE, numeric())) {
    expect_error(cd_pvi(congress = congress), "congress")
  }
  expect_error(cd_pvi(geography = "county"), "district.*state")
})

test_that("availability exposes PVI missingness without downloading maps", {
  local_mocked_bindings(
    get_lewis_sf = function(...) stop("Unexpected map retrieval"),
    get_census_cd_sf = function(...) stop("Unexpected map retrieval")
  )
  availability <- cd_available(quiet = TRUE)
  pvi_rows <- availability[availability$accessor == "cd_pvi", ]
  expect_identical(pvi_rows$year, seq.int(1999L, 2027L, 2L))
  expect_true(all(grepl("/435 district values; gaps are NA", pvi_rows$source, fixed = TRUE)))
  expect_match(pvi_rows$source[pvi_rows$year == 1999L], "412/435")
  expect_match(pvi_rows$source[pvi_rows$year == 2027L], "435/435")
})
