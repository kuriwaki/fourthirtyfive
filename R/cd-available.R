# Written by Codex

#' List available congressional district data
#'
#' Print a compact guide to the package's data functions, their coverage, and
#' their sources. Availability of bundled dotmaps, hexmaps, and district names
#' is read from the package data index. PVI coverage counts are read from the
#' bundled PVI table. No maps are downloaded or loaded.
#'
#' @param quiet Logical. Set to `TRUE` to suppress the guide and obtain only the
#'   returned availability table.
#'
#' @return Invisibly, a tibble with one row per available function and Congress,
#'   and columns `accessor`, `year` (the Congress's starting year), `congress`,
#'   and `source`. Availability indicates that a dataset can be requested; it
#'   does not imply that every product uses distinct geometry for every Congress.
#'
#' @details Boundary maps cover Congresses 1 through 120 and are retrieved from
#'   Lewis's historical congressional district boundaries or the US Census.
#'   The 120th Congress combines Census boundary releases. Bundled hexmaps for
#'   2005 through 2011 reuse a map generated for the 111th Congress (2009);
#'   those maps do not reconstruct every historical boundary change. See the
#'   individual functions for data sources and limitations.
#'
#' @family congressional district functions
#'
#' @examples
#' cd_available()
#' available <- cd_available(quiet = TRUE)
#' subset(available, accessor == "cd_hexmap")
#'
#' @export
cd_available <- function(quiet = FALSE) {
  if (!is.logical(quiet) || length(quiet) != 1L || is.na(quiet)) {
    cli::cli_abort("{.arg quiet} must be {.val TRUE} or {.val FALSE}.")
  }

  data_index <- utils::data(package = "fourthirtyfive")$results
  items <- if (is.null(data_index)) character() else data_index[, "Item"]
  boundary_congresses <- seq_len(120L)
  boundaries <- tibble::tibble(
    accessor = "cd_boundaries",
    year = cong_to_firstyear(boundary_congresses),
    congress = boundary_congresses,
    source = .cd_available_sources("cd_boundaries", boundary_congresses)
  )
  prefixes <- c(
    cd_dotmap = "shp_dot_", cd_hexmap = "shp_hex_", cd_names = "info_"
  )
  bundled <- lapply(names(prefixes), function(accessor) {
    years <- .cd_available_years(items, prefixes[[accessor]])
    congresses <- year_to_cong(years)
    sources <- .cd_available_sources(accessor, congresses)
    tibble::tibble(
      accessor = rep(accessor, length(years)),
      year = years,
      congress = congresses,
      source = sources
    )
  })
  pvi_data <- .cd_pvi_table()
  pvi_congresses <- sort(unique(pvi_data$cong[pvi_data$geography == "district"]))
  pvi_available <- tibble::tibble(
    accessor = rep("cd_pvi", length(pvi_congresses)),
    year = cong_to_firstyear(pvi_congresses),
    congress = pvi_congresses,
    source = vapply(pvi_congresses, function(congress) {
      .cd_pvi_source_summary(pvi_data[pvi_data$cong == congress, ])
    }, character(1))
  )
  available <- dplyr::bind_rows(boundaries, bundled, pvi_available)

  if (!quiet) {
    cli::cli_h2("Available congressional district data")
    summary_sources <- c(
      cd_boundaries = "Lewis / US Census",
      cd_dotmap = "Lewis / US Census, dodged centroids",
      cd_hexmap = "hexmap / The Downballot",
      cd_names = "Daily Kos / The Downballot / contributors",
      cd_pvi = "The Cook Political Report; public-source gaps are NA"
    )
    for (accessor in c("cd_boundaries", names(prefixes), "cd_pvi")) {
      product <- available[available$accessor == accessor, ]
      if (nrow(product) == 0L) {
        cli::cli_bullets(c("*" = "{.fun {accessor}}: no bundled data."))
      } else {
        year_range <- .cd_available_range(product$year, step = 2L)
        congress_range <- .cd_available_range(product$congress)
        source <- summary_sources[[accessor]]
        cli::cli_bullets(c(
          "*" = "{.fun {accessor}}: {year_range} (Congresses {congress_range}); {source}."
        ))
      }
    }
    cli::cli_text("Years refer to the start of a Congress, not its election year.")
    cli::cli_text("Historical hexmaps for 2005-2011 reuse the generated 2009 map.")
    cli::cli_text("PVI tables flag unavailable and documented unchanged values; inspect their status column.")
  }

  invisible(available)
}

# Availability helpers ----

.cd_available_years <- function(items, prefix) {
  # R's data index can decorate an item as "object (documentation_topic)".
  item_names <- sub("[[:space:]]+\\(.*\\)$", "", trimws(items))
  candidates <- item_names[startsWith(item_names, prefix)]
  year_strings <- substring(candidates, nchar(prefix) + 1L)
  valid_years <- year_strings[grepl("^[0-9]{4}$", year_strings)]
  sort(unique(as.integer(valid_years)))
}

.cd_available_sources <- function(accessor, congress) {
  switch(accessor,
    cd_boundaries = dplyr::case_when(
      congress <= 112L ~ "Lewis historical boundaries",
      congress == 120L ~ "US Census (mixed boundary releases)",
      TRUE ~ "US Census"
    ),
    cd_dotmap = dplyr::if_else(
      congress <= 112L,
      "Lewis-based dodged centroids",
      "US Census-based dodged centroids"
    ),
    cd_hexmap = dplyr::if_else(
      congress <= 112L,
      "Generated 2009 hexmap (reused for 2005-2011)",
      "The Downballot"
    ),
    cd_names = dplyr::case_when(
      congress <= 112L ~ "Zachary Donnini",
      congress >= 120L ~ "fourthirtyfive contributors",
      TRUE ~ "Daily Kos / The Downballot"
    )
  )
}

.cd_available_range <- function(values, step = 1L) {
  values_sorted <- sort(unique(values))
  if (length(values_sorted) == 1L) {
    return(as.character(values_sorted))
  }
  if (all(diff(values_sorted) == step)) {
    first <- min(values_sorted)
    last <- max(values_sorted)
    return(as.character(cli::format_inline("{first}-{last}")))
  }
  paste(values_sorted, collapse = ", ")
}
