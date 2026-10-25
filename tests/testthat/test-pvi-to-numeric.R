# Written by Codex

test_that("Cook PVI labels become signed proportions for either party", {
  labels <- c("R+10", "R+4", "EVEN", "D+4", "D+10")
  expect_equal(pvi_to_numeric(labels), c(-0.10, -0.04, 0, 0.04, 0.10))
  expect_equal(pvi_to_numeric(labels, party = "R"), c(0.10, 0.04, 0, -0.04, -0.10))
  expect_equal(0.5 + pvi_to_numeric("R+10", party = "R"), 0.60)
})

test_that("PVI conversion preserves precision, missing values, and names", {
  labels <- c(first = " d + 2.5 ", second = "r+0.25", tie = "even", missing = NA)
  expected <- c(first = 0.025, second = -0.0025, tie = 0, missing = NA_real_)
  expect_equal(pvi_to_numeric(labels), expected)
  expect_equal(pvi_to_numeric(labels, party = "r"), -expected)
  expect_identical(pvi_to_numeric(c(NA_character_, NA_character_)), c(NA_real_, NA_real_))
  expect_identical(pvi_to_numeric(character()), numeric())
  expect_equal(pvi_to_numeric(factor(c("D+3", "EVEN", NA))), c(0.03, 0, NA_real_))
  expect_identical(pvi_to_numeric(c("D+0", "R+0")), c(0, 0))
})

test_that("PVI conversion rejects malformed labels and invalid arguments", {
  malformed <- c("", " ", "D4", "R-4", "R+-4", "D+", "I+3", "4", "D+1 0", "R+Inf")
  for (label in malformed) {
    expect_error(pvi_to_numeric(label), "PVI labels")
  }
  expect_error(pvi_to_numeric(1), "character vector or factor")
  expect_error(pvi_to_numeric(list("D+4")), "character vector or factor")
  expect_error(pvi_to_numeric(matrix("D+4")), "character vector or factor")
  expect_error(pvi_to_numeric("D+4", party = "I"), "party.*D.*R")
  expect_error(pvi_to_numeric("D+4", party = NA_character_), "party.*D.*R")
  expect_error(pvi_to_numeric("D+4", party = c("D", "R")), "party.*D.*R")
  expect_error(pvi_to_numeric("D+4", party = 1), "party.*D.*R")
  expect_error(pvi_to_numeric(glue::glue("R+{stringr::str_dup('9', 400)}")), "too large")
})
