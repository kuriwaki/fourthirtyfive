# Written by Codex

test_that("normal vote data expose numeric scores and explicit source gaps", {
  data_env <- new.env(parent = emptyenv())
  utils::data(list = "normal_vote", package = "fourthirtyfive", envir = data_env)
  stacked <- get("normal_vote", envir = data_env, inherits = FALSE)
  expect_s3_class(stacked, "tbl_df")
  expect_named(stacked, c(
    "cong", "election_year", "geography", "state", "cd", "normal_vote",
    "status", "accessed"
  ))
  expect_type(stacked$cong, "integer")
  expect_type(stacked$election_year, "integer")
  expect_type(stacked$normal_vote, "double")
  expect_s3_class(stacked$accessed, "Date")
  expect_setequal(stacked$geography, c("district", "state"))
  expect_setequal(stacked$status, c("calculated", "unavailable"))
  expect_identical(is.na(stacked$normal_vote), stacked$status == "unavailable")
  expect_true(all(is.finite(stacked$normal_vote[!is.na(stacked$normal_vote)])))
  expect_true(all(abs(stacked$normal_vote[!is.na(stacked$normal_vote)]) <= 1))
  expect_true(all(stacked$election_year == cong_to_firstyear(stacked$cong) - 1L))
  expect_identical(
    cd_normal_vote(), stacked[stacked$geography == "district", ]
  )
  expect_identical(
    cd_normal_vote(geography = "state"), stacked[stacked$geography == "state", ]
  )

  numeric_scores <- stacked$normal_vote[!is.na(stacked$normal_vote)]
  expect_true(any(abs(numeric_scores * 100 - round(numeric_scores * 100)) > 1e-6))
})

test_that("normal vote identifiers cover congressional maps and all states", {
  districts <- cd_normal_vote()
  states <- cd_normal_vote(geography = "state")
  expect_identical(anyDuplicated(districts[c("cong", "cd")]), 0L)
  expect_identical(anyDuplicated(states[c("cong", "state")]), 0L)
  expect_true(all(table(districts$cong) == 435L))
  expect_true(all(table(states$cong) == 51L))
  expect_true(all(grepl("^[A-Z]{2}-[0-9]{2}$", districts$cd)))
  expect_false(any(grepl("-00$", districts$cd)))
  expect_identical(substr(districts$cd, 1, 2), districts$state)
  expect_true(all(is.na(states$cd)))
  for (congress_id in unique(states$cong)) {
    expect_setequal(states$state[states$cong == congress_id], c(datasets::state.abb, "DC"))
  }
})

test_that("recent normal vote coverage preserves matching-map requirements", {
  complete <- cd_normal_vote(year = 2025)
  expect_identical(nrow(complete), 435L)
  expect_false(anyNA(complete$normal_vote))
  expect_true(all(complete$status == "calculated"))

  recent <- cd_normal_vote(year = 2027)
  redrawn_states <- c("AL", "CA", "FL", "LA", "NC", "OH", "TN", "TX", "UT")
  unavailable <- recent$status == "unavailable"
  expect_identical(sum(unavailable), 173L)
  expect_identical(sum(!unavailable), 262L)
  expect_setequal(recent$state[unavailable], redrawn_states)
  expect_identical(unavailable, recent$state %in% redrawn_states)
  expect_true(all(is.na(recent$normal_vote[unavailable])))
  expect_true(all(!is.na(recent$normal_vote[!unavailable])))

  expect_false(anyNA(cd_normal_vote(year = 2025, geography = "state")$normal_vote))
  expect_false(anyNA(cd_normal_vote(year = 2027, geography = "state")$normal_vote))
})

test_that("normal vote selections preserve order and the year convention", {
  recent <- cd_normal_vote(year = 2027)
  earlier <- cd_normal_vote(year = 2025)
  expect_identical(recent, cd_normal_vote(congress = 120))
  expect_identical(recent, cd_normal_vote(year = 2027, congress = 119))
  expect_identical(recent, cd_normal_vote(year = c(2027, 2027)))
  expect_identical(
    cd_normal_vote(year = c(2027, 2025)), dplyr::bind_rows(recent, earlier)
  )
  expect_identical(
    cd_normal_vote(congress = c(120, 119, 120)), dplyr::bind_rows(recent, earlier)
  )
  expect_identical(
    cd_normal_vote(congress = c(120, 119), geography = "state"),
    dplyr::bind_rows(
      cd_normal_vote(year = 2027, geography = "state"),
      cd_normal_vote(year = 2025, geography = "state")
    )
  )
})

test_that("normal vote selections reject malformed or unsupported requests", {
  for (year in list(
    2025.5, NA_real_, Inf, "2025", TRUE, numeric(), -2025, 0,
    1e30, 2025 + 1i, matrix(2025)
  )) {
    expect_error(cd_normal_vote(year = year), "year")
  }
  expect_error(cd_normal_vote(year = 2024), "odd Congress start years")
  for (congress in list(
    119.5, NA_real_, Inf, "119", TRUE, numeric(), -119, 0,
    1e30, 119 + 1i, matrix(119)
  )) {
    expect_error(cd_normal_vote(congress = congress), "congress")
  }
  expect_error(cd_normal_vote(year = 1789), "not bundled.*1789")
  expect_error(cd_normal_vote(congress = 1), "not bundled.*1")
  expect_error(cd_normal_vote(geography = "county"), "district.*state")
})

test_that("district normal vote agrees with independently weighted source shares", {
  input_path <- testthat::test_path("..", "..", "data-raw", "normal-vote", "district-shares.csv")
  baseline_path <- testthat::test_path("..", "..", "data-raw", "normal-vote", "national-baselines.csv")
  skip_if_not(file.exists(input_path) && file.exists(baseline_path), "Source inputs are absent in installed-package tests.")
  skip_if_not_installed("readr")
  district_inputs <- readr::read_csv(input_path, show_col_types = FALSE)
  national_inputs <- readr::read_csv(baseline_path, show_col_types = FALSE)
  expect_identical(anyDuplicated(national_inputs$presidential_year), 0L)
  expect_true(all(is.finite(national_inputs$dem_two_party_share)))
  expect_true(all(national_inputs$dem_two_party_share > 0 & national_inputs$dem_two_party_share < 1))
  national_older <- national_inputs[national_inputs$presidential_year == 2020, ]
  national_newer <- national_inputs[national_inputs$presidential_year == 2024, ]
  expect_identical(nrow(national_older), 1L)
  expect_identical(nrow(national_newer), 1L)

  weighted_national_share <- 0.25 * national_older$dem_two_party_share +
    0.75 * national_newer$dem_two_party_share
  examples <- list(
    `2025` = c("CA-12", "TN-09", "WY-01"),
    `2027` = c("IL-01", "NY-12", "WY-01")
  )
  for (map_year in names(examples)) {
    selected_inputs <- district_inputs[
      district_inputs$year == as.integer(map_year) &
        district_inputs$cd %in% examples[[map_year]],
    ]
    expect_identical(nrow(selected_inputs), 3L)
    expect_true(all(selected_inputs$presidential_year_older == 2020))
    expect_true(all(selected_inputs$presidential_year_newer == 2024))
    expected <- 0.25 * selected_inputs$dem_share_older +
      0.75 * selected_inputs$dem_share_newer - weighted_national_share
    observed <- cd_normal_vote(year = as.integer(map_year))
    expect_equal(
      observed$normal_vote[match(selected_inputs$cd, observed$cd)], expected,
      tolerance = 1e-14
    )
  }
})

test_that("state normal vote compares saved state votes with the national lookup", {
  state_path <- testthat::test_path("..", "..", "data-raw", "normal-vote", "state-votes.csv")
  baseline_path <- testthat::test_path("..", "..", "data-raw", "normal-vote", "national-baselines.csv")
  skip_if_not(file.exists(state_path) && file.exists(baseline_path), "Source inputs are absent in installed-package tests.")
  skip_if_not_installed("readr")
  state_inputs <- readr::read_csv(state_path, show_col_types = FALSE)
  national_inputs <- readr::read_csv(baseline_path, show_col_types = FALSE)
  expected_differences <- vapply(c(2020, 2024), function(election_year) {
    state_votes <- state_inputs[state_inputs$presidential_year == election_year, ]
    national_share <- national_inputs$dem_two_party_share[
      national_inputs$presidential_year == election_year
    ]
    expect_setequal(state_votes$state, c(datasets::state.abb, "DC"))
    expect_length(national_share, 1L)
    dc_votes <- state_votes[state_votes$state == "DC", ]
    dc_votes$dem_votes / (dc_votes$dem_votes + dc_votes$rep_votes) -
      national_share
  }, numeric(1))
  states <- cd_normal_vote(year = 2025, geography = "state")
  expect_equal(
    states$normal_vote[states$state == "DC"],
    sum(c(0.25, 0.75) * expected_differences), tolerance = 1e-14
  )
})

test_that("the retired Cook data and accessors are not bundled", {
  index_items <- utils::data(package = "fourthirtyfive")$results[, "Item"]
  item_names <- sub("[[:space:]]+\\(.*\\)$", "", index_items)
  expect_true("normal_vote" %in% item_names)
  expect_false(any(grepl("^pvi($|_)", item_names)))
  expect_false(any(c("cd_pvi", "pvi_to_numeric") %in% getNamespaceExports("fourthirtyfive")))
})
