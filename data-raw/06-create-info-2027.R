# Written by Codex, checked by Shiro
# Run from the package root to rebuild data/info_2027.rda.

# Read source data ----
library(dplyr)

load("data/info_2025.rda")

names_sheet_url <- "https://docs.google.com/spreadsheets/d/1uxD-dKP1DBj_JLM1dXt-K2r8bHhU6o8IIIXCSFcEwaM/edit#gid=0"

# The source sheet is publicly readable; no Google account is needed.
googlesheets4::gs4_deauth()
district_names_raw <- googlesheets4::read_sheet(
  names_sheet_url,
  sheet = "Sheet1",
  range = "A2:F",
  col_names = c(
    "state", "district", "cook_label_2025", "description_2025",
    "changed", "description_2027"
  ),
  col_types = "ciccic"
)

# Validate manual labels ----
district_names <- district_names_raw |>
  filter(!if_all(everything(), is.na)) |>
  transmute(
    cd = as.character(glue::glue(
      "{state}-{stringr::str_pad(district, width = 2, pad = '0')}"
    )),
    changed,
    description_2027
  )

if (any(!district_names$changed %in% c(0L, 1L))) {
  stop("Every district in the names sheet must have a 0 or 1 in column E.")
}
if (any(
  district_names$changed == 1L &
    (is.na(district_names$description_2027) | district_names$description_2027 == "")
)) {
  stop("Every district marked changed in column E needs a name in column F.")
}

# Create 120th Congress info ----
# Column F overrides the packaged 2025 name only when column E is 1.
# Ignore the sheet's 2025 names (column D) and any column F text when E is 0.
district_name_updates <- district_names |>
  filter(changed == 1L) |>
  select(cd, description_2027)

info_2027 <- info_2025 |>
  left_join(district_name_updates, by = "cd", relationship = "one-to-one") |>
  transmute(
    cong = 120,
    cd,
    cd_description = coalesce(description_2027, cd_description)
  )

stopifnot(
  nrow(info_2027) == 435L,
  !anyDuplicated(info_2027$cd),
  !anyNA(info_2027$cd_description)
)

# Write package data ----
usethis::use_data(info_2027, overwrite = TRUE, compress = "xz")
