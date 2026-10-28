# Written by Codex

# Refresh independent source inputs ----
# Run from the package root. Without --download, use local ignored snapshots.
# With --download, fetch public Downballot sources first. State vote counts
# and national baselines are static tracked inputs and are not downloaded.

suppressPackageStartupMessages(library(dplyr))

input_dir <- file.path("data-raw", "normal-vote")
raw_dir <- file.path(input_dir, "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

map_sources <- readr::read_csv(
  file.path(input_dir, "map-sources.csv"),
  col_types = readr::cols(
    .default = readr::col_character(), year = readr::col_integer(),
    presidential_year_older = readr::col_integer(),
    presidential_year_newer = readr::col_integer(),
    sheet_id = readr::col_integer(), older_dem_column = readr::col_integer(),
    older_rep_column = readr::col_integer(), newer_dem_column = readr::col_integer(),
    newer_rep_column = readr::col_integer(), expected_complete = readr::col_integer(),
    accessed = readr::col_date()
  )
)
state_sources <- readr::read_csv(
  file.path(input_dir, "state-sources.csv"),
  col_types = readr::cols(
    .default = readr::col_character(), presidential_year = readr::col_integer(),
    accessed = readr::col_date()
  )
)
national_baselines <- readr::read_csv(
  file.path(input_dir, "national-baselines.csv"),
  col_types = readr::cols(
    presidential_year = readr::col_integer(), dem_two_party_share = readr::col_double(),
    source_url = readr::col_character(), accessed = readr::col_date()
  )
)
download_requested <- "--download" %in% commandArgs(trailingOnly = TRUE)

# Download public vote totals without display rounding ----
download_downballot <- function(source_row) {
  source_url <- glue::glue(
    "https://docs.google.com/spreadsheets/d/{source_row$spreadsheet_id}/gviz/tq",
    "?gid={source_row$sheet_id}&headers=0&tqx=out:json",
    "&range={utils::URLencode(source_row$source_range, reserved = TRUE)}"
  )
  json_path <- tempfile(fileext = ".json")
  on.exit(unlink(json_path), add = TRUE)
  utils::download.file(source_url, json_path, mode = "wb", quiet = TRUE)
  response_text <- readr::read_file(json_path)
  # Visualization responses wrap JSON in a callback. Read numeric `v` cells,
  # never formatted `f` cells or CSV exports that round fractional estimates.
  response_start <- regexpr("(", response_text, fixed = TRUE)[[1L]]
  response_end <- max(gregexpr(")", response_text, fixed = TRUE)[[1L]])
  response_json <- substr(response_text, response_start + 1L, response_end - 1L)
  response_data <- jsonlite::fromJSON(response_json, simplifyVector = FALSE)
  stopifnot(identical(response_data$status, "ok"))
  cells <- response_data$table$rows
  read_numeric_column <- function(column) {
    if (is.na(column)) return(rep(NA_real_, length(cells)))
    vapply(cells, function(row) {
      if (length(row$c) < column) return(NA_real_)
      cell <- row$c[[column]]
      if (is.null(cell$v)) NA_real_ else suppressWarnings(as.double(cell$v))
    }, numeric(1))
  }
  raw_votes <- tibble::tibble(
    cd = vapply(cells, function(row) {
      value <- row$c[[1L]]$v
      if (is.null(value)) NA_character_ else as.character(value)
    }, character(1)),
    dem_votes_older = read_numeric_column(source_row$older_dem_column),
    rep_votes_older = read_numeric_column(source_row$older_rep_column),
    dem_votes_newer = read_numeric_column(source_row$newer_dem_column),
    rep_votes_newer = read_numeric_column(source_row$newer_rep_column)
  ) |>
    filter(grepl("^[A-Z]{2}-(AL|[0-9]{2})$", cd))
  stopifnot(nrow(raw_votes) == 435L, !anyDuplicated(raw_votes$cd))
  readr::write_csv(raw_votes, file.path(raw_dir, source_row$raw_file))
}

if (download_requested) {
  download_sources <- distinct(map_sources, raw_file, .keep_all = TRUE)
  for (i in seq_len(nrow(download_sources))) {
    download_downballot(download_sources[i, ])
  }
}

# Derive district two-party shares from saved vote totals ----
normalize_map <- function(source_row) {
  raw_votes <- readr::read_csv(
    file.path(raw_dir, source_row$raw_file),
    col_types = readr::cols(cd = readr::col_character(), .default = readr::col_double())
  )
  stopifnot(
    nrow(raw_votes) == 435L, !anyDuplicated(raw_votes$cd),
    all(is.na(raw_votes$dem_votes_older) == is.na(raw_votes$rep_votes_older)),
    all(is.na(raw_votes$dem_votes_newer) == is.na(raw_votes$rep_votes_newer))
  )
  normalized_shares <- raw_votes |>
    transmute(
      year = source_row$year, state = substr(cd, 1L, 2L),
      cd = stringr::str_replace(cd, "-(AL|00)$", "-01"),
      presidential_year_older = source_row$presidential_year_older,
      presidential_year_newer = source_row$presidential_year_newer,
      dem_share_older = dem_votes_older / (dem_votes_older + rep_votes_older),
      dem_share_newer = dem_votes_newer / (dem_votes_newer + rep_votes_newer),
      accessed = if (download_requested) Sys.Date() else source_row$accessed
    )
  stopifnot(
    sum(!is.na(normalized_shares$dem_share_older) &
      !is.na(normalized_shares$dem_share_newer)) == source_row$expected_complete
  )
  normalized_shares
}
district_shares <- lapply(seq_len(nrow(map_sources)), function(i) {
  normalize_map(map_sources[i, ])
}) |>
  bind_rows() |>
  arrange(year, cd)

# Keep only derived Downballot inputs in tracked files ----
readr::write_csv(district_shares, file.path(input_dir, "district-shares.csv"))

map_sources_dated <- map_sources |>
  mutate(accessed = if (download_requested) Sys.Date() else accessed)
readr::write_csv(map_sources_dated, file.path(input_dir, "map-sources.csv"))

# Record one provenance row per map and source ----
district_provenance <- map_sources_dated |>
  transmute(
    year, source = "The Downballot", geography = "district",
    presidential_years = glue::glue("{presidential_year_older},{presidential_year_newer}"),
    source_url, source_range = glue::glue("Vote totals!{source_range}"),
    accessed, n_rows = 435L, n_calculable = expected_complete, notes
  )
state_provenance <- lapply(seq_len(nrow(map_sources_dated)), function(i) {
  source_row <- map_sources_dated[i, ]
  state_sources |>
    filter(presidential_year %in% c(
      source_row$presidential_year_older, source_row$presidential_year_newer
    )) |>
    transmute(
      year = source_row$year, source = "Federal Election Commission",
      geography = "state", presidential_years = as.character(presidential_year),
      source_url, source_range = source_table, accessed, n_rows = 51L,
      n_calculable = 51L,
      notes = "Static official vote-count snapshot for the 50 states and DC; not refreshed automatically."
    )
}) |>
  bind_rows()
national_provenance <- lapply(seq_len(nrow(map_sources_dated)), function(i) {
  source_row <- map_sources_dated[i, ]
  national_baselines |>
    filter(presidential_year %in% c(
      source_row$presidential_year_older, source_row$presidential_year_newer
    )) |>
    transmute(
      year = source_row$year, source = "Wikipedia national candidate totals",
      geography = "national", presidential_years = as.character(presidential_year),
      source_url, source_range = "national-baselines.csv", accessed, n_rows = 1L,
      n_calculable = 1L,
      notes = "Fixed Democratic two-party share D/(D+R), verified from national candidate totals."
    )
}) |>
  bind_rows()
provenance <- bind_rows(district_provenance, state_provenance, national_provenance) |>
  arrange(year, source, presidential_years)
readr::write_csv(provenance, file.path(input_dir, "provenance.csv"))
message("Normalized independent inputs and map-specific provenance refreshed.")
