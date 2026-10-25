# Written by Codex

#' Compatibility accessors
#'
#' These functions retain the original `fourthirtyfive` interface. For new
#' code, use [cd_boundaries()], [cd_dotmap()], [cd_hexmap()], and [cd_names()].
#' Arguments and return values are unchanged.
#'
#' @param year,congress See the corresponding `cd_` accessor.
#' @inheritParams cd_boundaries
#' @return The same `sf` object or tibble as the corresponding `cd_` accessor.
#' @name legacy-accessors
#' @export
load_cd_shps <- function(year = NULL, congress = NULL, epsg = 5070,
                         simplify = TRUE, cache = TRUE, state = NULL) {
  cd_boundaries(
    year = year, congress = congress, epsg = epsg,
    simplify = simplify, cache = cache, state = state
  )
}

#' @rdname legacy-accessors
#' @export
load_shp_dot <- function(year = NULL, congress = NULL) {
  cd_dotmap(year = year, congress = congress)
}

#' @rdname legacy-accessors
#' @export
load_shp_hex <- function(year = NULL, congress = NULL) {
  cd_hexmap(year = year, congress = congress)
}

#' @rdname legacy-accessors
#' @export
load_cd_info <- function(year = NULL, congress = NULL) {
  cd_names(year = year, congress = congress)
}
