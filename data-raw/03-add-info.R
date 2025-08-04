library(tidyverse)
library(googlesheets4)
library(remotes)
library(ccesMRPprep)
library(sf)
library(cdmap)

# match cd names to 2005-2009 ---
## download 2005-2009 cd names
names_raw <- gs4_get("1D6out76Jblwvs9bwhb-XQM3ctyp2UjnGrttsqGlX_tY")
c111 <- read_sheet(names_raw, sheet = "111th") |> select(cd, name)
c109 <- read_sheet(names_raw, sheet = "109th-midcycle") |> select(cd, name)

## 109th redistricting in GA and TX
shp_dot_2005_info <- shp_dot_2005 |>
  left_join(c111, by = "cd") |>
  # overwrite names for GA and TX w/ c109
  left_join(c109|> rename(name_109 = name), by = "cd") |>
  # replace c111 with c109 for GA and TX
  mutate(info_2005 = if_else(str_starts(cd, "GA") | str_starts(cd, "TX"), name_109, name)) |>
  select(-name_109, -name)

shp_dot_2007_info <- shp_dot_2007 |>
  left_join(c111, by = "cd") |>
  rename(info_2007 = name)

shp_dot_2009_info <- shp_dot_2009 |>
  left_join(c111, by = "cd") |>
  rename(info_2009 = name)

# match cd names to 2011-2019 ---
## download 2018 and 2024 cd names
names_2018 <- read_sheet(names_raw, sheet = "2018") |> select(cd, dailykos_name)

## between the 2012-14 and 2016 data, FL, NC, VA changed their districts
### no "dailykos_name" on `cd_info_2012`
shp_dot_2011_info <- shp_dot_2011 |>
  left_join(cd_info_2016 |> select(cd, dailykos_name)) |>
  rename(info_2011 = dailykos_name)

shp_dot_2013_info <- shp_dot_2013 |>
  left_join(cd_info_2016 |> select(cd, dailykos_name)) |>
  rename(info_2013 = dailykos_name)

shp_dot_2015_info <- shp_dot_2015 |>
  left_join(cd_info_2016 |> select(cd, dailykos_name)) |>
  rename(info_2015 = dailykos_name)

## between the 2016 and 2018 data, PA changed their districts
shp_dot_2017_info <- shp_dot_2017 |>
  left_join(names_2018, by = "cd") |>
  rename(info_2018 = dailykos_name)

## between the 2018 and 2020 data, NC changed their districts
shp_dot_2019_info <- shp_dot_2019 |>
  left_join(cd_info_2020 |> select(cd, dailykos_name)) |>
  rename(info_2019 = dailykos_name)

# match cd names to 2021-2023 ---
shp_dot_2021_info <- shp_dot_2021 |>
  left_join(cd_info_2022 |> select(cd, dailykos_name)) |>
  rename(info_2021 = dailykos_name)

## between the 2022 and 2024 data, 4 districts changed their districts: AL, GA, LA, and NC.
shp_dot_2023_info <- shp_dot_2023 |>
  left_join(cd_info_2024 |> select(cd, dailykos_name)) |>
  rename(info_2023 = dailykos_name)

