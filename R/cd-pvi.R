# Written by Codex

# Data retrieval ----
#' Cook PVI values
#'
#' @description Cook PVI is a measure of the partisan lean of a district based on
#'  previous Presidential election results, measuring
#'  "how partisan a district or a state is compared to the nation as a whole" (Cook).
#'  This dataset takes the publicly available Cook
#'  values.
#'
#' @inheritParams cd_params
#' @param year Congress start years: `1999` selects the 1998 election maps.
#'   Omit both `year` and `congress` to return all bundled Congresses.
#' @param geography `"district"` for House districts or `"state"` for the
#'   50 states and DC.
#'
#' @details See [The Cook Political Report](https://www.cookpolitical.com/cook-pvi)
#' for computation. Scores use the two most recent presidential elections as of
#' the regular House election, weighted 75% for the newer and 25% for the older.
#' For example, `year = 2027` (the 2026 election) uses 2024 and 2020.
#' The exception is the 2003 House table: it uses only 2000 because comparable
#' 1996 results were unavailable after redistricting. Unavailable scores are `NA`.
#'
#' @author [The Cook Political Report](https://www.cookpolitical.com/)
#' @source [Cook PVI historical archive](https://www.cookpolitical.com/cook-pvi).
#' @seealso [pvi] for columns, [pvi_to_numeric()] for numeric interpretation,
#'   [cd_available()] for coverage.
#'
#' @examples
#' cd_pvi(year = 2027)
#' cd_pvi(congress = 120, geography = "state")
#'
#' @examplesIf requireNamespace("ggredist", quietly = TRUE)
#' library(dplyr)
#' library(ggplot2)
#'
#' # 2027 House hex map (2026 elections); render at 5 x 3 inches.
#' hex_pvi <- cd_hexmap(year = 2027) |>
#'   sf::st_make_valid() |>
#'   left_join(
#'     cd_pvi(year = 2027) |> select(cong, cd, pvi),
#'     by = c("cong", "cd"), relationship = "one-to-one"
#'   )
#'
#' ggplot(hex_pvi, aes(group = cd, fill = pvi_to_numeric(pvi))) +
#'   ggredist::geom_district(color = "white", linewidth = 0.1) +
#'   ggredist::scale_fill_party_c(
#'     name = "Cook PVI", midpoint = 0, limits = c(-0.4, 0.4),
#'     labels = ggredist::label_party_margin(midpoint = 0)
#'   ) +
#'   ggredist::theme_map(
#'     text = element_text(family = "sans", size = 11, color = "black"),
#'     legend.text = element_text(size = 11),
#'     legend.position = "bottom", legend.title.position = "top",
#'     legend.key.width = grid::unit(1.2, "cm"),
#'     legend.key.height = grid::unit(0.25, "cm"),
#'     plot.margin = margin(2, 2, 2, 2)
#'   )
#'
#' @export
cd_pvi <- function(year = NULL, congress = NULL,
                   geography = c("district", "state")) {
  geography <- match.arg(geography)
  value <- .cd_pvi_table()
  available_years <- sort(unique(cong_to_firstyear(
    value$cong[value$geography == geography]
  )))

  if (is.null(year) && !is.null(congress)) {
    if (!is.numeric(congress) || !length(congress) ||
        anyNA(congress) || any(!is.finite(congress)) ||
        any(congress != trunc(congress)) || any(congress < 106 | congress > 120)) {
      cli::cli_abort("{.arg congress} must contain whole Congress numbers from 106 through 120.")
    }
    year <- cong_to_firstyear(congress)
  }
  if (is.null(year)) {
    years <- available_years
  } else {
    if (!is.numeric(year) || !length(year) || anyNA(year) ||
        any(!is.finite(year)) || any(year != trunc(year)) ||
        any(year < 1999 | year > 2027)) {
      cli::cli_abort("{.arg year} must contain whole Congress start years from 1999 through 2027.")
    }
    if (any(year %% 2 != 1)) {
      cli::cli_abort(c(
        "{.arg year} must contain odd Congress start years.",
        "i" = "For the 1998 regular election, use {.code year = 1999}."
      ))
    }
    years <- unique(as.integer(year))
  }
  if (!length(available_years)) {
    cli::cli_abort("No Cook PVI tables are bundled in this installation.")
  }
  missing_years <- setdiff(years, available_years)
  if (length(missing_years)) {
    cli::cli_abort(c(
      "Cook PVI data are not bundled for Congress start year{?s} {.val {missing_years}}.",
      "i" = "Use {.fn cd_available} to inspect coverage."
    ))
  }

  load_one <- function(y) {
    selected <- value[
      value$cong == year_to_cong(y) & value$geography == geography,
    ]
    if (!nrow(selected) && !is.null(year)) {
      cli::cli_abort("No {.val {geography}} PVI values are bundled for {.val {y}}.")
    }
    selected
  }
  dplyr::bind_rows(lapply(years, load_one))
}

# Numeric conversion ----
#' Convert Cook PVI labels to signed proportions
#'
#' @param x Character or factor PVI labels. Missing values remain missing;
#'   malformed labels produce an error.
#' @param party Party receiving positive values: `"D"` (default) or `"R"`.
#' @return A numeric vector preserving length and names. `"EVEN"` is zero;
#'   one PVI point is `0.01` in absolute value.
#' @details The sign and scale are modeled on
#'   [ggredist's `label_party_margin()`](https://alarm-redist.org/ggredist/reference/label_party.html)
#'   with `midpoint = 0` (`reverse = TRUE` for `party = "R"`).
#' @note For Democrats, `"R+10"` becomes `-0.10`; at a 50% national baseline,
#'   this corresponds to roughly 60% Republican two-party share.
#' @seealso [cd_pvi()] for Cook's definition and source.
#' @examples
#' pvi_to_numeric(c("R+4", "EVEN", "D+2.5", NA))
#' pvi_to_numeric(c("R+4", "EVEN", "D+2.5"), party = "R")
#' @export
pvi_to_numeric <- function(x, party = "D") {
  if ((!is.character(x) && !is.factor(x)) || !is.null(dim(x))) {
    cli::cli_abort("{.arg x} must be a character vector or factor of PVI labels.")
  }
  if (!is.character(party) || length(party) != 1L || is.na(party)) {
    cli::cli_abort("{.arg party} must be {.val D} or {.val R}.")
  }
  party_code <- toupper(trimws(party))
  if (!party_code %in% c("D", "R")) {
    cli::cli_abort("{.arg party} must be {.val D} or {.val R}.")
  }

  labels <- toupper(trimws(as.character(x)))
  matches <- stringr::str_match(labels, "^([DR])\\s*\\+\\s*([0-9]+(?:\\.[0-9]+)?)$")
  invalid <- !is.na(labels) & labels != "EVEN" & is.na(matches[, 1])
  if (any(invalid)) {
    cli::cli_abort("{.arg x} must contain PVI labels such as {.val D+4}, {.val R+4}, or {.val EVEN}.")
  }

  magnitudes <- as.double(matches[, 3]) / 100
  if (any(!is.na(magnitudes) & !is.finite(magnitudes))) {
    cli::cli_abort("{.arg x} contains a PVI value too large to convert.")
  }
  signed <- magnitudes * ifelse(matches[, 2] == party_code, 1, -1)
  values <- replace(signed, which(labels == "EVEN"), 0)
  stats::setNames(values, names(x))
}

# Internal data helpers ----
.cd_pvi_table <- function() {
  data_env <- new.env(parent = emptyenv())
  utils::data(list = "pvi", package = "fourthirtyfive", envir = data_env)
  get("pvi", envir = data_env, inherits = FALSE)
}

.cd_pvi_source_summary <- function(value) {
  districts <- value[value$geography == "district", ]
  available <- sum(!is.na(districts$pvi))
  total <- nrow(districts)
  as.character(glue::glue("The Cook Political Report ({available}/{total} district values; gaps are NA)"))
}

# Bundled data ----
#' Historical Cook PVI data
#'
#' @name pvi
#' @docType data
#' @keywords datasets
#' @description Stacked data used by [cd_pvi()].
#'
#' @format A tibble with 7,290 rows for Congresses 106-120:
#' \describe{
#'   \item{cong}{Congress number.}
#'   \item{election_year}{Preceding regular House election year.}
#'   \item{geography}{`district` or `state`.}
#'   \item{state}{Two-letter abbreviation, including DC for statewide rows.}
#'   \item{cd}{District code; at-large districts use `01`. Missing for states.}
#'   \item{pvi}{Cook label, such as `D+4`, `R+4`, or `EVEN`.}
#'   \item{status}{`archive`: direct value; `unchanged`: documented reuse;
#'     `unavailable`: PVI is `NA`.}
#'   \item{accessed}{Collection date; missing for unavailable values.}
#' }
#' @seealso [cd_pvi()] for source and selection; [pvi_to_numeric()] for conversion.
NULL
