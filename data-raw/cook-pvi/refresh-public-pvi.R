# Written by Codex
# Run from the package root; add --download to refresh public Datawrapper files.
# Current race-table snapshots require a browser refresh when Cook returns 403.

# Source manifest ----
library(dplyr)

pvi_source_dir <- "data-raw/cook-pvi"
pvi_sources_raw <- readr::read_csv(
  file.path(pvi_source_dir, "sources.csv"),
  col_types = readr::cols(
    .default = readr::col_character(), release_year = readr::col_integer(),
    expected_rows = readr::col_integer(), accessed = readr::col_date()
  )
)
pvi_refresh <- "--download" %in% commandArgs(trailingOnly = TRUE)
pvi_sources <- if (pvi_refresh) {
  pvi_sources_raw |>
    mutate(accessed = if_else(source_type == "datawrapper", Sys.Date(), accessed))
} else pvi_sources_raw
pvi_state_codes <- stats::setNames(
  c(state.abb, "DC"), c(state.name, "District of Columbia")
)
strip_sort_key <- function(x) stringr::str_remove(x, "@@.*$")

# Refresh public downloads ----
# Dataset URLs are explicit assets of the publicly rendered embedded charts.
# No subscriber pages or authenticated APIs are used.
if (pvi_refresh) {
  pvi_downloads <- filter(pvi_sources, source_type == "datawrapper")
  for (i in seq_len(nrow(pvi_downloads))) {
    utils::download.file(
      pvi_downloads$dataset_url[[i]],
      file.path(pvi_source_dir, "raw", pvi_downloads$raw_file[[i]]),
      mode = "wb", quiet = TRUE
    )
  }
  readr::write_csv(pvi_sources, file.path(pvi_source_dir, "sources.csv"), na = "")
  message("Public datasets refreshed. Review changed values and source dates before rebuilding package data.")
}

# Parse raw snapshots ----
read_public_pvi <- function(source) {
  path <- file.path(pvi_source_dir, "raw", source$raw_file[[1]])
  is_race <- source$source_type[[1]] == "race_snapshot"
  raw <- if (is_race) {
    readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()))
  } else {
    readr::read_tsv(path, col_types = readr::cols(.default = readr::col_character()))
  }
  geography <- source$geography[[1]]
  raw_id <- strip_sort_key(raw[[source$id_column[[1]]]])
  district <- if (geography == "district") {
    if (is_race) {
      as.character(glue::glue(
        "{raw_id}-{stringr::str_pad(raw$dist, width = 2, pad = '0')}"
      ))
    } else {
      stringr::str_replace(
        stringr::str_replace(raw_id, "^([A-Z]{2})$", "\\1-AL"),
        "-AL$", "-00"
      )
    }
  } else rep(NA_character_, nrow(raw))
  state <- if (geography == "district") stringr::str_sub(district, 1, 2) else {
    if (is_race) raw_id else unname(pvi_state_codes[raw_id])
  }
  parsed <- tibble::tibble(
    geography = geography, release_year = source$release_year[[1]],
    cd = district, state = state,
    pvi = strip_sort_key(raw[[source$pvi_column[[1]]]]),
    source_url = if (is_race) raw$source_url else source$source_url[[1]],
    accessed = if (is_race) readr::parse_date(raw$accessed) else source$accessed[[1]]
  )
  stopifnot(
    nrow(parsed) == source$expected_rows[[1]],
    all(parsed$state %in% c(state.abb, "DC")),
    all(grepl("^([DR]\\+[0-9]+|EVEN)$", parsed$pvi)),
    !anyNA(parsed[c("state", "pvi", "source_url", "accessed")]),
    !anyDuplicated(parsed[c("state", "cd")])
  )
  parsed
}
pvi_public_values <- lapply(seq_len(nrow(pvi_sources)), function(i) {
  read_public_pvi(pvi_sources[i, ])
}) |>
  bind_rows()
stopifnot(!anyDuplicated(pvi_public_values[c("geography", "release_year", "state", "cd")]))

# Write normalized public values ----
readr::write_csv(
  pvi_public_values, file.path(pvi_source_dir, "archive-values.csv"), na = ""
)
message(glue::glue(
  "Wrote {scales::comma(nrow(pvi_public_values))} public PVI observations."
))
