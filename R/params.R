# Written by Codex

#' Shared congressional district parameters
#'
#' Common argument definitions inherited by the data accessors and
#' congressional session conversion helpers.
#'
#' @name cd_params
#' @param year Integer vector of years, such as `2025` or `c(2025, 2027)`.
#'   For data accessors, use Congress start years, rather than election years.
#' @param congress Integer vector of Congress numbers, such as `119` or
#'   `c(119, 120)`.
#' @param cd Character district code with a two-letter state abbreviation and
#'   a two-digit district number, such as `"TN-09"`. At-large districts use
#'   `"01"`, such as `"DE-01"`.
#' @param state State names, two-letter abbreviations, or FIPS codes, such as
#'   `"Tennessee"`, `"TN"`, or `47`.
#' @param epsg Integer EPSG code for the output coordinate reference system
#'   (default `5070`).
#' @param simplify Logical. For Lewis-era Congresses (1-112), simplify
#'   boundaries to about Census cartographic `20m` resolution (default `TRUE`).
#'   Ignored for Congresses 113-119, which use Census cartographic `20m` files.
#'   For the 120th Congress, simplify the nine redrawn states together after
#'   assembling the map. Use `FALSE` for full TIGER/Line detail in those nine
#'   states; all other states retain the previous cycle's cartographic `20m`
#'   boundaries.
#' @param cache Logical. Cache assembled 2027 maps in the current R session
#'   (default `TRUE`). Set `FALSE` to rebuild from the boundary inputs.
#'   Download caching is controlled separately by
#'   `options(tigris_use_cache = TRUE)`.
#' @keywords internal
NULL
