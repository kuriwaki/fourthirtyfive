# Written by Codex

#' Accessor aliases
#'
#' Alternative names for [cd_boundaries()], [cd_dotmap()], [cd_hexmap()], and
#' [cd_names()], with the same arguments and return values.
#'
#' @inheritParams cd_params
#' @details Available periods and state selection follow the corresponding
#'   `cd_` accessor.
#' @return The same `sf` object or tibble as the corresponding `cd_` accessor.
#' @name accessor-aliases
#' @export
load_cd_shps <- function(year = NULL, congress = NULL, epsg = 5070,
                         simplify = TRUE, cache = TRUE, state = NULL) {
  cd_boundaries(
    year = year, congress = congress, epsg = epsg,
    simplify = simplify, cache = cache, state = state
  )
}

#' @rdname accessor-aliases
#' @export
load_shp_dot <- function(year = NULL, congress = NULL) {
  cd_dotmap(year = year, congress = congress)
}

#' @rdname accessor-aliases
#' @export
load_shp_hex <- function(year = NULL, congress = NULL) {
  cd_hexmap(year = year, congress = congress)
}

#' @rdname accessor-aliases
#' @export
load_cd_info <- function(year = NULL, congress = NULL) {
  cd_names(year = year, congress = congress)
}
