# Written by Codex

# Data retrieval ----
#' Presidential normal vote
#'
#' @description Retrieve a district's or state's presidential voting lean
#'   relative to the nation, following the publicly documented 75/25 methodology
#'   of the well-known
#'   [Cook Partisan Voting Index (Cook PVI)](https://www.cookpolitical.com/cook-pvi).
#'   Values are calculated independently from public election results. The
#'   returned numeric measure is a signed proportion: positive values indicate
#'   a Democratic lean and negative values indicate a Republican lean.
#'
#' @inheritParams cd_params
#' @param year Congress start years. For example, `2025` selects districts used
#'   in the 2024 House election. Omit both `year` and `congress` to return all
#'   bundled Congresses. If both are supplied, `year` takes precedence.
#' @param geography `"district"` for House districts or `"state"` for the
#'   50 states and DC.
#'
#' @return A tibble with the columns documented in [normal_vote].
#'
#' @details For each of the two most recent presidential elections as of the
#'   regular House election, calculate Democratic two-party vote share, and label
#'   them X<sub>2</sub> (older) and X<sub>1</sub> (newer). Then we compute the
#'   normal vote as 0.25*(X<sub>2</sub> - Avg(X<sub>2</sub>)) + 0.75*(X<sub>1</sub> - Avg(X<sub>1</sub>))
#'   where the Avg( ) operator indicates the national popular vote
#'   (not exactly, but close to, an average). As noted above, this follows the
#'   method of the Cook PVI.
#'
#'   In light of the intellectual-property language in
#'   [The Cook Political Report's terms and conditions](https://www.cookpolitical.com/terms-and-conditions),
#'   we chose not to distribute its publicly available PVI scores in this package.
#'   Instead, we calculate district values using
#'   The Downballot's [compilation](https://www.the-downballot.com/p/data).
#'   Presidential vote is not regularly computed by congressional district.
#'   We are grateful for Downballot's substantial work and for their generous
#'   reuse policy, which welcomes reuse with a citation and a source link.
#'   These independently calculated values may differ from Cook's published
#'   scores because the underlying vote allocations can differ.
#'   The Downballot's compilation does not yet provide both 2020 and 2024
#'   presidential results for all redrawn 2027 districts. The package therefore
#'   provides 262 normal vote estimates for the 2027 map and leaves 173 missing.
#'   Cook's published PVI scores for that map can be obtained publicly from its
#'   [district page](https://www.cookpolitical.com/cook-pvi/2026-partisan-voting-index/district-map-and-list)
#'   (published July 2026).
#'
#' @source District presidential results from
#'   [The Downballot](https://www.the-downballot.com/p/data).
#' @seealso [normal_vote] for columns and missingness.
#' @family congressional district functions
#'
#' @examples
#' cd_normal_vote(year = 2025)
#' cd_normal_vote(congress = 119, geography = "state")
#'
#' @examplesIf requireNamespace("ggredist", quietly = TRUE)
#' library(dplyr)
#' library(ggplot2)
#'
#' hex_normal_vote <- cd_hexmap(year = 2025) |>
#'   left_join(
#'     cd_normal_vote(year = 2025) |> select(cong, cd, normal_vote),
#'     by = c("cong", "cd"), relationship = "one-to-one"
#'   )
#'
#' ggplot(hex_normal_vote, aes(group = cd, fill = normal_vote)) +
#'   ggredist::geom_district(color = "white", linewidth = 0.1) +
#'   ggredist::scale_fill_party_c(
#'     name = "Normal vote", midpoint = 0, limits = c(-0.4, 0.4),
#'     labels = ggredist::label_party_margin(midpoint = 0)
#'   ) +
#'   ggredist::theme_map()
#'
#' @export
cd_normal_vote <- function(year = NULL, congress = NULL,
                           geography = c("district", "state")) {
  geography <- match.arg(geography)
  value <- .cd_normal_vote_table()
  geography_values <- value[value$geography == geography, ]
  available_congresses <- sort(unique(geography_values$cong))
  available_years <- cong_to_firstyear(available_congresses)

  if (!length(available_congresses)) {
    cli::cli_abort("No {.val {geography}} normal vote data are bundled in this installation.")
  }

  if (!is.null(year)) {
    if (!.cd_normal_vote_valid_selection(year)) {
      cli::cli_abort("{.arg year} must contain whole Congress start years.")
    }
    if (any(year %% 2 != 1)) {
      cli::cli_abort(c(
        "{.arg year} must contain odd Congress start years.",
        "i" = "For the 2024 regular House election, use {.code year = 2025}."
      ))
    }
    selected_years <- unique(as.integer(year))
    missing_years <- setdiff(selected_years, available_years)
    if (length(missing_years)) {
      cli::cli_abort(c(
        "Normal vote data are not bundled for Congress start year{?s} {.val {missing_years}}.",
        "i" = "Use {.fn cd_available} to inspect coverage."
      ))
    }
    selected_congresses <- year_to_cong(selected_years)
  } else if (!is.null(congress)) {
    if (!.cd_normal_vote_valid_selection(congress)) {
      cli::cli_abort("{.arg congress} must contain positive whole Congress numbers.")
    }
    selected_congresses <- unique(as.integer(congress))
    missing_congresses <- setdiff(selected_congresses, available_congresses)
    if (length(missing_congresses)) {
      cli::cli_abort(c(
        "Normal vote data are not bundled for Congress{?es} {.val {missing_congresses}}.",
        "i" = "Use {.fn cd_available} to inspect coverage."
      ))
    }
  } else {
    return(geography_values)
  }

  dplyr::bind_rows(lapply(selected_congresses, function(congress_id) {
    geography_values[geography_values$cong == congress_id, ]
  }))
}

# Internal data helpers ----
.cd_normal_vote_valid_selection <- function(x) {
  is.numeric(x) && !is.complex(x) && is.null(dim(x)) && length(x) > 0L &&
    !anyNA(x) && all(is.finite(x)) && all(x == trunc(x)) &&
    all(x > 0) && all(x <= .Machine$integer.max)
}

.cd_normal_vote_table <- function() {
  data_env <- new.env(parent = emptyenv())
  utils::data(list = "normal_vote", package = "fourthirtyfive", envir = data_env)
  get("normal_vote", envir = data_env, inherits = FALSE)
}

.cd_normal_vote_source_summary <- function(value) {
  districts <- value[value$geography == "district", ]
  available <- sum(!is.na(districts$normal_vote))
  total <- nrow(districts)
  as.character(glue::glue(
    "Calculated from The Downballot ({available}/{total} district values; gaps are NA)"
  ))
}

# Bundled data ----
#' Presidential normal vote data
#'
#' @name normal_vote
#' @docType data
#' @keywords datasets
#' @description Stacked data used by [cd_normal_vote()], following the publicly
#'   documented 75/25 methodology of the
#'   [Cook Partisan Voting Index (Cook PVI)](https://www.cookpolitical.com/cook-pvi).
#'   Calculations compare
#'   The Downballot's district presidential results, or saved Federal Election
#'   Commission state vote counts, with a fixed lookup of national Democratic
#'   two-party vote shares. Explicit missing values identify maps for which a
#'   matching pair of presidential results is not available.
#'
#' @format A tibble with one row per Congress and geography unit:
#' \describe{
#'   \item{cong}{Integer Congress number.}
#'   \item{election_year}{Integer year of the preceding regular House election.}
#'   \item{geography}{`district` or `state`.}
#'   \item{state}{Two-letter abbreviation, including DC for statewide rows.}
#'   \item{cd}{District code; at-large districts use `01`. Missing for states.}
#'   \item{normal_vote}{Unrounded signed proportion, positive for Democratic
#'     lean and negative for Republican lean. Missing when the required
#'     presidential results on matching district maps are unavailable.}
#'   \item{status}{`calculated` or `unavailable`.}
#'   \item{accessed}{Date the source inputs were accessed. An unavailable score
#'     can retain a date when the source was inspected but lacked a matching
#'     pair of results.}
#' }
#' @seealso [cd_normal_vote()] for the formula, sources, and selection.
NULL
