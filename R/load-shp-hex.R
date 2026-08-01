#' @title Load Daily Kos / Downballot Elections Cartogram
#'
#' @description Loads Daily Kos Elections cartogram shapefile of each district.
#'
#' @param year Integer vector of years from 2005-2025, or 2026.
#' @param congress Integer vector of Congress numbers from the 109th-119th Congress.
#' @param map_2026 Which 2026 hexmap to use, `"a"` or `"b"`; see Details. Only
#'  relevant when `year` includes 2026. Defaults to `NULL`, in which case the
#'  function will message about the two options and use `"b"`.
#'
#' @details Years indicate the year of the January in which the Congress starts.
#'  For example, to get shapefiles for the 2022 election, set `year = 2023`.
#'
#'  2026 is a special case: several states redrew districts mid-decade ahead of
#'  the 2026 elections, so two hexmaps are available for that year. `map_2026 = "a"`
#'  keeps the same (pre-redistricting) districts as `shp_hex_2025`. `map_2026 = "b"`
#'  reflects the new district lines adopted for 2026 in CA, FL, NC, OH, TN, UT, and TX
#'  (AL, LA, and MO are unchanged under either option).
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
#' @author Daniel Donner (2013–2025 shapefiles); Cory McCartan (2005-2011 hexmap generation)
#' @source 2013–2025: \url{https://the-db.co/maps}. 2005-2011: created with
#'   \href{https://github.com/CoryMcCartan/hexmap}{CoryMcCartan/hexmap} using
#'   district boundaries from Jeffrey B. Lewis's historical shapefiles.
#' @return An sf dataframe with 435 rows
#'
#' @examples
#' # load one dataset
#' load_shp_hex(year = 2019)
#'
#' # 2026 has two options; this messages about them and uses "b"
#' load_shp_hex(year = 2026)
#'
#' # choose explicitly
#' load_shp_hex(year = 2026, map_2026 = "a")
#'
#' # plot points combined with state outline
#' library(ggplot2)
#'
#' load_shp_hex(year = 2019) |>
#'   ggplot() +
#'   geom_sf() +
#'   theme_void()
#'
#' @name load_shp_hex
#' @export

load_shp_hex <- function(year = NULL, congress = NULL, map_2026 = NULL) {
  if (!is.null(year)) {
    congress <- year_to_cong(year)
  } else if (!is.null(congress)) {
    year <- cong_to_firstyear(congress)
  }
  year <- as.integer(year)
  if (anyNA(year)) stop("`year` must be integer years like 2011 or 2005:2009.", call. = FALSE)
  if (any(year %% 2 == 0 & year != 2026)) {
    stop("As of now, only odd years (or 2026) for the start of each Congress are available.", call. = FALSE)
  }

  if (2026L %in% year) {
    if (is.null(map_2026)) {
      cli::cli_inform(c(
        "i" = "Two hexmaps are available for {.val 2026}:",
        "*" = "{.val a}: same districts as {.code shp_hex_2025} (pre-redistricting).",
        "*" = "{.val b}: updated districts adopted for 2026 in CA, FL, NC, OH, TN, UT, and TX (AL, LA, MO unchanged).",
        "i" = "Using {.val b}. Set {.code map_2026 = \"a\"} to use the other option instead."
      ))
      map_2026 <- "b"
    }
    map_2026 <- match.arg(map_2026, c("a", "b"))
  }

  one <- function(y) {
    obj <- if (y == 2026L) paste0("shp_hex_2026", map_2026) else paste0("shp_hex_", y)
    utils::data(list = obj, package = "fourthirtyfive", envir = environment())
    if (!exists(obj, envir = environment(), inherits = FALSE)) {
      stop("Available years are odd years between 2005-2025, or 2026.", call. = FALSE)
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
#' @format Each object is for a particular year. The year indicates the start
#'  of that Congress. Each observational is a congressional district, represented by
#'  a cartogram.
#' @source 2013–2025 coordinates are from The Downballot's maps database.
#'   2005-2011 (\code{shp_hex_2005} through \code{shp_hex_2011}) are created through \href{https://github.com/CoryMcCartan/hexmap}{CoryMcCartan/hexmap}.
#'
#' @aliases shp_hex_2005 shp_hex_2007 shp_hex_2009 shp_hex_2011 shp_hex_2013 shp_hex_2015 shp_hex_2017 shp_hex_2019 shp_hex_2021 shp_hex_2023 shp_hex_2025 shp_hex_2026a shp_hex_2026b
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
