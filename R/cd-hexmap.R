# Written by Codex
#' @title Congressional district hex maps
#'
#' @description Loads Daily Kos Elections cartogram shapefile of each district.
#'
#' @inheritParams cd_params
#'
#' @details Supply `year` or `congress`. Bundled hexmaps cover Congresses
#'   109-120 (start years 2005-2027).
#'
#'  Years indicate the year of the January in which the Congress starts.
#'  For example, to get shapefiles for the 2022 election, set `year = 2023`.
#'
#'  `shp_hex_2027` reflects district lines redrawn mid-decade ahead of the 2026
#'  elections.
#'  These districts elect the members who take their seats in the 120th Congress,
#'  which starts January 2027.
#'
#' @note For 2013 to 2021, we use the same shapefile (Downballot's v2.1wm), but note that
#'  between the 2016 and 2020 data, PA changed their districts but did not add/remove any.
#'  Between the 2012-14 and 2016 data, FL, NC, VA did mid-cycle redistricting.
#'  The 2005-2011 hexmap is created using Cory McCartan's
#'  \href{https://github.com/CoryMcCartan/hexmap}{hexmap} package that assigns hex units into districts
#'  by a redistricting algorithm. The same hexmap (the 111th Congress / 2009 districts) is reused
#'  for all of 2005-2011, since the number of districts per state was constant over the
#'  2000-census apportionment decade.
#'
#' @section Licensing and attribution:
#' The Downballot-derived cartogram material is the Congressional District
#' Hexmap by Daniel Donner for [The Downballot](https://the-db.co/maps), licensed
#' under [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).
#' Older source files may be branded Daily Kos Elections.
#'
#' The package standardizes district identifiers, repairs narrow geometry gaps,
#' translates the 2023 cartogram to align with later maps, and reuses version
#' 2.1 for 2013-2021. The generated 2005-2011 maps also use The Downballot's
#' state layout for placement and scaling. The README figures and logo adapt
#' this map material through plotting, recoloring, cropping, or composition.
#'
#' Retain the creator credit, source and license links, and an indication of
#' changes when publishing or redistributing the licensed map material.
#' Full attribution and scope are in the installed `LICENSE.note`, located by
#' `system.file("LICENSE.note", package = "fourthirtyfive")`. The package's R
#' code remains under the MIT License.
#'
#' @author Daniel Donner (2013–2027 shapefiles); Cory McCartan (2005-2011 hexmap generation)
#' @source 2013–2027: \url{https://the-db.co/maps}. 2005-2011: created with
#'   \href{https://github.com/CoryMcCartan/hexmap}{CoryMcCartan/hexmap} using
#'   district boundaries from Jeffrey B. Lewis's historical shapefiles.
#' @return An sf dataframe with 435 rows
#'
#' @examples
#' # load one dataset
#' cd_hexmap(year = 2019)
#'
#' # districts used for the members entering Congress in January 2027
#' cd_hexmap(year = 2027)
#'
#' # plot points combined with state outline
#' library(ggplot2)
#'
#' cd_hexmap(year = 2019) |>
#'   ggplot() +
#'   geom_sf() +
#'   theme_void()
#'
#' @name cd_hexmap
#' @family congressional district functions
#' @seealso [cd_available()] for supported years and Congresses.
#' @export

cd_hexmap <- function(year = NULL, congress = NULL) {
  if (!is.null(year)) {
    congress <- year_to_cong(year)
  } else if (!is.null(congress)) {
    year <- cong_to_firstyear(congress)
  }
  year <- as.integer(year)
  if (anyNA(year)) stop("`year` must be integer years like 2011 or 2005:2009.", call. = FALSE)
  if (any(year %% 2 == 0)) stop("As of now, only odd years for the start of each Congress are available.", call. = FALSE)

  one <- function(y) {
    obj <- paste0("shp_hex_", y)
    utils::data(list = obj, package = "fourthirtyfive", envir = environment())
    if (!exists(obj, envir = environment(), inherits = FALSE)) {
      stop("Available years are odd years between 2005-2027.", call. = FALSE)
    }
    get(obj, envir = environment())
  }

  lst <- lapply(year, one)
  if (length(year) == 1L) {
    lst[[1]]
  } else {
    dplyr::bind_rows(lst)
  }
}

#' @title Hexmap: Daily Kos / Downballot Elections Cartogram
#' @name shp_hex
#' @docType data
#' @keywords datasets
#' @description Loads Daily Kos / Downballot Elections cartogram shapefile of coordinates for each district.
#'
#' @inheritSection cd_hexmap Licensing and attribution
#'
#' @format Each object is for a particular year. The year indicates the start
#'  of that Congress. Each observation is a congressional district, represented by
#'  a cartogram.
#' @source 2013–2027 coordinates are from The Downballot's maps database.
#'   2005-2011 (\code{shp_hex_2005} through \code{shp_hex_2011}) are created through \href{https://github.com/CoryMcCartan/hexmap}{CoryMcCartan/hexmap}.
#'
#' @aliases shp_hex_2005 shp_hex_2007 shp_hex_2009 shp_hex_2011 shp_hex_2013 shp_hex_2015 shp_hex_2017 shp_hex_2019 shp_hex_2021 shp_hex_2023 shp_hex_2025 shp_hex_2027
#'
#' @examples
#' library(sf)
#' library(ggplot2)
#'
#' shp_hex_2019 |>
#'   ggplot() +
#'   geom_sf() +
#'   theme_bw()
NULL
