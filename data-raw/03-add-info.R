#' @name info
#' @title Create congressional district info datasets

library(tidyverse)
library(googlesheets4)
library(remotes)
library(ccesMRPprep)
library(sf)
library(fourthirtyfive)

source("data-raw/helpers/cd-name-corrections.R")

# Match district names to 2005-2009 ----
## Read source names and corrections ----
googlesheets4::gs4_deauth()
names_raw <- gs4_get("1D6out76Jblwvs9bwhb-XQM3ctyp2UjnGrttsqGlX_tY")
c109 <- read_sheet(names_raw, sheet = "109th-midcycle") |> select(cd, name)
c111 <- read_sheet(names_raw, sheet = "111th") |> select(cd, name)
c115 <- read_sheet(names_raw, sheet = "2018") |> select(cd, dailykos_name)
historical_name_corrections <- read_cd_name_corrections(names_raw)

## 109th redistricting in GA and TX ----
info_2005 <- shp_dot_2005 |>
  left_join(c111, by = "cd", relationship = "one-to-one") |>
  # overwrite names for GA and TX w/ c109
  left_join(c109 |> rename(name_109 = name), by = "cd", relationship = "one-to-one") |>
  # replace c111 with c109 for GA and TX
  mutate(cd_description = if_else(str_starts(cd, "GA") | str_starts(cd, "TX"), name_109, name)) |>
  select(-name_109, -name) |>
  st_drop_geometry() |>
  as_tibble()

info_2007 <- shp_dot_2007 |>
  left_join(c111, by = "cd", relationship = "one-to-one") |>
  rename(cd_description = name) |>
  st_drop_geometry() |>
  as_tibble()

info_2009 <- shp_dot_2009 |>
  left_join(c111, by = "cd", relationship = "one-to-one") |>
  rename(cd_description = name) |>
  st_drop_geometry() |>
  as_tibble()

# Match district names to 2011-2019 ----
info_2011 <- shp_dot_2011 |>
  left_join(c111, by = "cd", relationship = "one-to-one") |>
  rename(cd_description = name) |>
  st_drop_geometry() |>
  as_tibble()

## Correct earlier FL and NC names for the shared 113th/114th plan ----
# The sheet supplies historical names where cd_info_2016 describes a later map.
info_2013 <- shp_dot_2013 |>
  left_join(cd_info_2016 |> select(cd, cd_description = dailykos_name),
            by = "cd", relationship = "one-to-one") |>
  st_drop_geometry() |>
  as_tibble() |>
  apply_cd_name_corrections(historical_name_corrections)

info_2015 <- shp_dot_2015 |>
  left_join(cd_info_2016 |> select(cd, cd_description = dailykos_name),
            by = "cd", relationship = "one-to-one") |>
  st_drop_geometry() |>
  as_tibble() |>
  apply_cd_name_corrections(historical_name_corrections)

info_2017 <- shp_dot_2017 |>
  left_join(cd_info_2016 |> select(cd, cd_description = dailykos_name),
            by = "cd", relationship = "one-to-one") |>
  st_drop_geometry() |>
  as_tibble()

## Pennsylvania changes for the 116th Congress ----
info_2019 <- shp_dot_2019 |>
  left_join(cd_info_2018 |> select(cd, cd_description = dailykos_name),
            by = "cd", relationship = "one-to-one") |>
  st_drop_geometry() |>
  as_tibble()

# Match district names to 2021-2025 ----
## Correct North Carolina names for the 117th Congress ----
info_2021 <- shp_dot_2021 |>
  left_join(cd_info_2020 |> select(cd, cd_description = dailykos_name),
            by = "cd", relationship = "one-to-one") |>
  st_drop_geometry() |>
  as_tibble() |>
  apply_cd_name_corrections(historical_name_corrections)

## between the 2022 and 2024 data, 4 districts changed their districts: AL, GA, LA, and NC.
info_2023 <- shp_dot_2023 |>
  left_join(cd_info_2022 |> select(cd, cd_description = dailykos_name),
            by = "cd", relationship = "one-to-one") |>
  st_drop_geometry() |>
  as_tibble()

info_2025 <- shp_dot_2025 |>
  left_join(cd_info_2024 |> select(cd, cd_description = dailykos_name),
            by = "cd", relationship = "one-to-one") |>
  st_drop_geometry() |>
  as_tibble()

# Write ----
usethis::use_data(info_2005, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2007, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2009, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2011, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2013, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2015, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2017, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2019, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2021, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2023, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2025, overwrite = TRUE, compress = "xz")
