library(tidyverse)
library(googlesheets4)
library(remotes)
library(ccesMRPprep)
library(sf)
library(cdmap)

# match cd names to 2005-2009 ---
## download 2005-2009 and 2018 cd names
names_raw <- gs4_get("1D6out76Jblwvs9bwhb-XQM3ctyp2UjnGrttsqGlX_tY")
c109 <- read_sheet(names_raw, sheet = "109th-midcycle") |> select(cd, name)
c111 <- read_sheet(names_raw, sheet = "111th") |> select(cd, name)
c115 <- read_sheet(names_raw, sheet = "2018") |> select(cd, dailykos_name)

## 109th redistricting in GA and TX
info_2005 <- shp_dot_2005 |>
  left_join(c111, by = "cd") |>
  # overwrite names for GA and TX w/ c109
  left_join(c109|> rename(name_109 = name), by = "cd") |>
  # replace c111 with c109 for GA and TX
  mutate(cd_description = if_else(str_starts(cd, "GA") | str_starts(cd, "TX"), name_109, name)) |>
  select(-name_109, -name) |>
  st_drop_geometry() |>
  as_tibble()

info_2007 <- shp_dot_2007 |>
  left_join(c111, by = "cd") |>
  rename(cd_description = name) |>
  st_drop_geometry() |>
  as_tibble()

info_2009 <- shp_dot_2009 |>
  left_join(c111, by = "cd") |>
  rename(cd_description = name) |>
  st_drop_geometry() |>
  as_tibble()

# match cd names to 2011-2019 ---
## download 2024 cd names
## use 2018 names from c115

info_2011 <- shp_dot_2011 |>
  left_join(c111, by = "cd") |>
  rename(cd_description = name) |>
  st_drop_geometry() |>
  as_tibble()

## between the 2012-14 and 2016 data, FL, NC, VA (maybe PA) changed their districts
## 113th Congress (January 2013-2015) vs 114th (January 2015-2017) (same)
info_2013 <- shp_dot_2013 |>
  left_join(cd_info_2016 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

info_2015 <- shp_dot_2015 |>
  left_join(cd_info_2016 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

info_2017 <- shp_dot_2017 |>
  left_join(cd_info_2016 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

## between the 2016 and 2018 data, PA changed their districts-- CD116
info_2019 <- shp_dot_2019 |>
  left_join(cd_info_2018 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

## between the 2018 and 2020 data, NC changed their districts
# match cd names to 2021-2023 ---
info_2021 <- shp_dot_2021 |>
  left_join(cd_info_2020 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

## between the 2022 and 2024 data, 4 districts changed their districts: AL, GA, LA, and NC.
info_2023 <- shp_dot_2023 |>
  left_join(cd_info_2022 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

info_2025 <- shp_dot_2025 |>
  left_join(cd_info_2024 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

# Write ---
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
