# Written by Codex

# Read corrections for specific congressional maps ----
read_cd_name_corrections <- function(spreadsheet) {
  corrections_raw <- googlesheets4::read_sheet(
    spreadsheet, sheet = "2026-10-corrections", range = "A:D",
    col_types = "iicc"
  )
  stopifnot(
    identical(names(corrections_raw), c(
      "congress_start", "congress_end", "cd", "cd_description"
    )),
    nrow(corrections_raw) > 0L,
    !anyNA(corrections_raw),
    all(corrections_raw$congress_start >= 1L),
    all(corrections_raw$congress_end <= 120L),
    all(corrections_raw$congress_start <= corrections_raw$congress_end),
    all(grepl("^[A-Z]{2}-[0-9]{2}$", corrections_raw$cd)),
    all(nzchar(trimws(corrections_raw$cd_description)))
  )
  corrections <- corrections_raw |>
    dplyr::mutate(cong = purrr::map2(congress_start, congress_end, seq.int)) |>
    tidyr::unnest(cong) |>
    dplyr::transmute(cong = as.double(cong), cd, cd_description_fix = cd_description)
  stopifnot(!anyDuplicated(corrections[c("cong", "cd")]))
  corrections
}

# Apply names only to the matching Congress and district ----
apply_cd_name_corrections <- function(info, corrections) {
  applicable <- dplyr::filter(corrections, cong %in% info$cong)
  unmatched <- dplyr::setdiff(applicable[c("cong", "cd")], info[c("cong", "cd")])
  if (nrow(unmatched)) {
    stop("A historical name correction does not match a district in this Congress.")
  }
  info |>
    dplyr::left_join(applicable, by = c("cong", "cd"), relationship = "one-to-one") |>
    dplyr::mutate(cd_description = dplyr::coalesce(cd_description_fix, cd_description)) |>
    dplyr::select(-cd_description_fix)
}
