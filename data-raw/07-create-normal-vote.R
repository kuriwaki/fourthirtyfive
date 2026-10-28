# Written by Codex

# Independent normal vote data ----
# Run from the package root. The builder only reads tracked, normalized
# district shares, static state totals, and one national baseline per election.

library(dplyr)

input_dir <- file.path("data-raw", "normal-vote")
district_shares <- readr::read_csv(
  file.path(input_dir, "district-shares.csv"),
  col_types = readr::cols(
    year = readr::col_integer(), state = readr::col_character(),
    cd = readr::col_character(), presidential_year_older = readr::col_integer(),
    presidential_year_newer = readr::col_integer(),
    dem_share_older = readr::col_double(), dem_share_newer = readr::col_double(),
    accessed = readr::col_date()
  )
)
state_votes <- readr::read_csv(
  file.path(input_dir, "state-votes.csv"),
  col_types = readr::cols(
    presidential_year = readr::col_integer(),
    state = readr::col_character(), dem_votes = readr::col_double(),
    rep_votes = readr::col_double(), accessed = readr::col_date()
  )
)
national_baselines <- readr::read_csv(
  file.path(input_dir, "national-baselines.csv"),
  col_types = readr::cols(
    presidential_year = readr::col_integer(), dem_two_party_share = readr::col_double(),
    source_url = readr::col_character(), accessed = readr::col_date()
  )
)

# Validate independent source inputs ----
stopifnot(
  !anyDuplicated(district_shares[c("year", "cd")]),
  !anyDuplicated(state_votes[c("presidential_year", "state")]),
  !anyDuplicated(national_baselines$presidential_year),
  all(district_shares$state %in% state.abb),
  all(substr(district_shares$cd, 1L, 2L) == district_shares$state),
  all(grepl("^[A-Z]{2}-[0-9]{2}$", district_shares$cd)),
  all(district_shares$year %% 2L == 1L),
  all(district_shares$presidential_year_newer ==
    (district_shares$year - 1L) - (district_shares$year - 1L) %% 4L),
  all(district_shares$presidential_year_older ==
    district_shares$presidential_year_newer - 4L),
  all(is.na(district_shares$dem_share_older) |
    dplyr::between(district_shares$dem_share_older, 0, 1)),
  all(is.na(district_shares$dem_share_newer) |
    dplyr::between(district_shares$dem_share_newer, 0, 1)),
  all(state_votes$dem_votes > 0), all(state_votes$rep_votes > 0),
  all(state_votes$state %in% c(state.abb, "DC")),
  all(dplyr::between(national_baselines$dem_two_party_share, 0, 1)),
  !anyNA(district_shares[c("year", "state", "cd", "accessed")]),
  !anyNA(state_votes), !anyNA(national_baselines)
)
roster_sizes <- district_shares |>
  count(year)
stopifnot(all(roster_sizes$n == 435L))
state_sizes <- state_votes |>
  count(presidential_year)
stopifnot(all(state_sizes$n == 51L), nrow(national_baselines) == 5L)

# Calculate full-precision district and state values ----
normal_vote_one_year <- function(map_year) {
  district_inputs <- district_shares |>
    filter(year == map_year)
  newer <- unique(district_inputs$presidential_year_newer)
  older <- unique(district_inputs$presidential_year_older)
  stopifnot(length(newer) == 1L, length(older) == 1L)
  baseline_newer <- national_baselines$dem_two_party_share[
    match(newer, national_baselines$presidential_year)
  ]
  baseline_older <- national_baselines$dem_two_party_share[
    match(older, national_baselines$presidential_year)
  ]
  stopifnot(!anyNA(c(baseline_newer, baseline_older)))

  district_values <- district_inputs |>
    transmute(
      state, cd,
      normal_vote = 0.25 * (dem_share_older - baseline_older) +
        0.75 * (dem_share_newer - baseline_newer),
      accessed
    )

  state_inputs <- state_votes |>
    filter(presidential_year %in% c(older, newer)) |>
    mutate(dem_share = dem_votes / (dem_votes + rep_votes))
  state_older <- state_inputs |>
    filter(presidential_year == older) |>
    transmute(state, dem_share_older = dem_share, accessed_older = accessed)
  state_newer <- state_inputs |>
    filter(presidential_year == newer) |>
    transmute(state, dem_share_newer = dem_share, accessed_newer = accessed)
  state_values <- tibble::tibble(state = sort(c(state.abb, "DC"))) |>
    left_join(state_older, by = "state", relationship = "one-to-one") |>
    left_join(state_newer, by = "state", relationship = "one-to-one") |>
    transmute(
      state, cd = NA_character_,
      normal_vote = 0.25 * (dem_share_older - baseline_older) +
        0.75 * (dem_share_newer - baseline_newer),
      accessed = pmax(accessed_older, accessed_newer)
    )

  bind_rows(
    mutate(district_values, geography = "district"),
    mutate(state_values, geography = "state")
  ) |>
    transmute(
      cong = as.integer((map_year - 1789L) / 2L + 1L),
      election_year = as.integer(map_year - 1L), geography, state, cd,
      normal_vote = as.double(normal_vote),
      status = if_else(is.na(normal_vote), "unavailable", "calculated"),
      accessed
    )
}

normal_vote <- lapply(sort(unique(district_shares$year)), normal_vote_one_year) |>
  bind_rows() |>
  arrange(cong, geography, state, cd)

stopifnot(
  !anyDuplicated(normal_vote[c("cong", "geography", "state", "cd")]),
  all(is.na(normal_vote$normal_vote) == (normal_vote$status == "unavailable")),
  all(is.na(normal_vote$normal_vote) | abs(normal_vote$normal_vote) < 1)
)

# Save package data and coverage ----
save(normal_vote, file = "data/normal_vote.rda", compress = "xz", version = 2)
normal_vote_coverage <- normal_vote |>
  group_by(cong, election_year, geography) |>
  summarize(
    n_total = n(), n_calculated = sum(status == "calculated"),
    n_unavailable = sum(status == "unavailable"), .groups = "drop"
  )
readr::write_csv(normal_vote_coverage, file.path(input_dir, "coverage.csv"))
print(normal_vote_coverage, n = Inf)
