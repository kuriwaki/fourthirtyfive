# Written by Codex
# Run from the package root. Raw public-source snapshots and their provenance
# live in data-raw/cook-pvi/. No network requests occur when cd_pvi() is called.

# Read and validate archive snapshots ----
library(dplyr)

pvi_releases <- readr::read_csv(
  "data-raw/cook-pvi-releases.csv",
  col_types = readr::cols(.default = readr::col_integer())
)
pvi_raw_source <- readr::read_csv(
  "data-raw/cook-pvi/archive-values.csv",
  col_types = readr::cols(
    geography = readr::col_character(), release_year = readr::col_integer(),
    cd = readr::col_character(), state = readr::col_character(),
    pvi = readr::col_character(), source_url = readr::col_character(),
    accessed = readr::col_date()
  )
)
pvi_raw <- pvi_raw_source |>
  mutate(cd = stringr::str_replace(cd, "-00$", "-01"))
presidential_newer <- pvi_releases$election_year - pvi_releases$election_year %% 4L
house_single_election <- pvi_releases$year == 2003L
stopifnot(
  identical(pvi_releases$year, seq.int(1999L, 2027L, 2L)),
  all(pvi_releases$election_year == pvi_releases$year - 1L),
  all(pvi_releases$district_presidential_year_newer == presidential_newer),
  all(pvi_releases$state_presidential_year_newer == presidential_newer),
  all(pvi_releases$state_presidential_year_older == presidential_newer - 4L),
  identical(is.na(pvi_releases$district_presidential_year_older), house_single_election),
  all(pvi_releases$district_presidential_year_older[!house_single_election] ==
    presidential_newer[!house_single_election] - 4L),
  all(pvi_raw$geography %in% c("district", "state")),
  all(pvi_raw$state %in% c(state.abb, "DC")),
  all(is.na(pvi_raw$cd[pvi_raw$geography == "state"])),
  all(grepl("^(D\\+[0-9]+(\\.[0-9]+)?|R\\+[0-9]+(\\.[0-9]+)?|EVEN)$", pvi_raw$pvi)),
  !anyNA(pvi_raw[c("release_year", "state", "pvi", "source_url", "accessed")]),
  !anyDuplicated(pvi_raw[c("geography", "release_year", "state", "cd")])
)
district_raw <- filter(pvi_raw, geography == "district")
stopifnot(
  all(grepl("^[A-Z]{2}-[0-9]{2}$", district_raw$cd)),
  all(substr(district_raw$cd, 1L, 2L) == district_raw$state),
  all(district_raw$state %in% state.abb),
  !anyNA(district_raw$cd)
)

# District rosters ----
# Use the package's district identifiers for each apportionment decade.
# The 1997 public Cook archive supplies the earlier 1990-census roster.
read_district_roster <- function(year) {
  if (year <= 2001L) {
    return(pvi_raw |>
      filter(geography == "district", release_year == 1997L) |>
      distinct(cd, state) |>
      arrange(cd))
  }
  roster_year <- if (year <= 2011L) 2005L else if (year <= 2021L) 2013L else 2023L
  object_name <- as.character(glue::glue("info_{roster_year}"))
  data_env <- new.env(parent = emptyenv())
  load(as.character(glue::glue("data/{object_name}.rda")), envir = data_env)
  get(object_name, envir = data_env) |>
    transmute(cd, state = substr(cd, 1L, 2L)) |>
    distinct() |>
    arrange(cd)
}

# Documented identical releases ----
# Cook's archive overview confirms each of these relationships:
# https://www.cookpolitical.com/cook-pvi
# 1999 changes only North Carolina and Virginia relative to 1997.
# 2009/2011 and 2013/2015 are identical pairs. 2023 is identical to 2022.
# State 2021 and 2022 use the same presidential results under the revised
# formula; original 50/50 PDFs are deliberately excluded.
pvi_equivalents <- tibble::tribble(
  ~geography, ~target_release_year, ~source_release_year, ~exclude_states,
  "district", 1999L, 1997L, "NC,VA",
  "district", 2009L, 2011L, "",
  "district", 2011L, 2009L, "",
  "district", 2013L, 2015L, "",
  "district", 2015L, 2013L, "",
  "district", 2023L, 2022L, "",
  "state", 2021L, 2022L, ""
)

select_archive_values <- function(geography_code, target_release_year) {
  direct <- pvi_raw |>
    filter(geography == geography_code, release_year == target_release_year) |>
    mutate(status = "archive")
  rules <- pvi_equivalents |>
    filter(geography == geography_code, .data$target_release_year == .env$target_release_year)
  alternatives <- lapply(seq_len(nrow(rules)), function(i) {
    excluded <- strsplit(rules$exclude_states[[i]], ",", fixed = TRUE)[[1]]
    pvi_raw |>
      filter(
        geography == geography_code,
        release_year == rules$source_release_year[[i]],
        !state %in% excluded
      ) |>
      mutate(status = "unchanged")
  })
  # Prefer the exact public release. Even archives described as identical can
  # differ in published rounding (2022 versus 2023 ID-02 is one such case).
  key <- if (geography_code == "district") "cd" else "state"
  supplements <- bind_rows(alternatives)
  if (nrow(supplements)) {
    supplements <- supplements[!supplements[[key]] %in% direct[[key]], ]
  }
  candidates <- bind_rows(direct, supplements)
  conflicting <- candidates |>
    group_by(state, cd) |>
    summarize(n_values = n_distinct(pvi), .groups = "drop") |>
    filter(n_values > 1L)
  if (nrow(conflicting)) {
    stop(glue::glue("Conflicting equivalent archive values for {geography_code} {target_release_year}."))
  }
  candidates |>
    distinct(state, cd, .keep_all = TRUE) |>
    transmute(state, cd, pvi, status, accessed)
}

# Build tables without filling unavailable values ----
build_geography <- function(release_row, geography_code) {
  year <- release_row$year[[1]]
  release_year <- release_row[[as.character(glue::glue("{geography_code}_release_year"))]][[1]]
  roster <- if (geography_code == "district") read_district_roster(year) else {
    tibble::tibble(state = sort(c(state.abb, "DC")), cd = NA_character_)
  }
  stopifnot(nrow(roster) == if (geography_code == "district") 435L else 51L)
  selected <- select_archive_values(geography_code, release_year)
  key <- if (geography_code == "district") "cd" else "state"
  if (length(setdiff(selected[[key]], roster[[key]]))) {
    stop(glue::glue("Archive district identifiers do not match the {year} roster."))
  }
  roster |>
    left_join(selected, by = c("state", "cd"), relationship = "one-to-one") |>
    transmute(
      cong = release_row$congress[[1]],
      election_year = release_row$election_year[[1]],
      geography = geography_code, state, cd, pvi,
      status = coalesce(status, "unavailable"),
      accessed
    )
}

pvi <- lapply(seq_len(nrow(pvi_releases)), function(i) {
  release_row <- pvi_releases[i, ]
  bind_rows(
    build_geography(release_row, "district"),
    build_geography(release_row, "state")
  )
}) |>
  bind_rows()

# Write package data and coverage audit ----
save(pvi, file = "data/pvi.rda", compress = "xz", version = 2)
pvi_coverage <- pvi |>
  group_by(cong, election_year, geography) |>
  summarize(
    n_total = n(), n_archive = sum(status == "archive"),
    n_unchanged = sum(status == "unchanged"),
    n_unavailable = sum(status == "unavailable"), .groups = "drop"
  )
readr::write_csv(pvi_coverage, "data-raw/cook-pvi/coverage.csv")
print(pvi_coverage, n = Inf)
if (any(pvi_coverage$n_unavailable > 0L)) {
  message("Public-source gaps are retained as NA with status = 'unavailable'.")
}
