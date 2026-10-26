# remotes::install_github("kuriwaki/ccesMRPprep")
library(ccesMRPprep)
library(tidyverse)
library(glue)
library(patchwork)
library(usethis)
library(sf)

source("data-raw/helpers/clean-hexmap.R")

# raw shps
# can download these shps from The Downballot maps database
# https://docs.google.com/spreadsheets/d/13XkF59JKzvw4SeSq5mbgIFrJfYjK4amg9JoQE5e9grQ/edit?gid=1250379179#gid=1250379179
cd_shp_2019 <- cd_shp_2021 <- read_sf("data-raw/hexmap_2020/HexCDv21wm/")
cd_shp_2023 <- read_sf("data-raw/hexmap_2022/HexCDv30wm/")
cd_shp_2025 <- read_sf("data-raw/hexmap_2024/HexCDv31wm/")
cd_shp_2027 <- read_sf("data-raw/hexmap_2026/HexCDv32wm")

# Standardize Downballot's v3.0 file with other years
bb_23 <- st_bbox(cd_shp_2023)
bb_25 <- st_bbox(cd_shp_2025)
st_geometry(cd_shp_2023) <- st_geometry(cd_shp_2023) +
  c(bb_25[["xmin"]] - bb_23[["xmin"]], bb_25[["ymin"]] - bb_23[["ymin"]])
st_crs(cd_shp_2023) <- st_crs(cd_shp_2025)

shp_hex_2019 <- cd_shp_2019 |>
  transmute(
    cong = 116,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd) |>
  clean_hexmap()

shp_hex_2021 <- cd_shp_2021 |>
  transmute(
    cong = 117,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd) |>
  clean_hexmap()

shp_hex_2023 <- cd_shp_2023 |>
  transmute(
    cong = 118,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd) |>
  clean_hexmap()

shp_hex_2025 <- cd_shp_2025 |>
  mutate(STATEAB = if_else(STATEAB == "01", "AL", STATEAB)) |>
  transmute(
    cong = 119,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd) |>
  clean_hexmap()

## shp_hex_2027: reflects district lines redrawn mid-decade ahead of the 2027  elections
## Named 2027 because these districts elect the members who take their seats
## in the 120th Congress, which starts January 2027.
shp_hex_2027 <- cd_shp_2027 |>
  mutate(STATEAB = if_else(STATEAB == "01", "AL", STATEAB)) |>
  transmute(
    cong = 120,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd) |>
  clean_hexmap()

## Use older version for now
### Between the 2012-14 and 2016 data, FL, NC, VA changed their districts
### Between the 2016 and 2018 data, PA changed their districts
shp_hex_2013 <- shp_hex_2019 |>
  mutate(cong = 113)
shp_hex_2015 <- shp_hex_2019 |>
  mutate(cong = 114)
shp_hex_2017 <- shp_hex_2019 |>
  mutate(cong = 115)

usethis::use_data(shp_hex_2013, overwrite = TRUE, compress = "xz", version = 2)
usethis::use_data(shp_hex_2015, overwrite = TRUE, compress = "xz", version = 2)
usethis::use_data(shp_hex_2017, overwrite = TRUE, compress = "xz", version = 2)
usethis::use_data(shp_hex_2019, overwrite = TRUE, compress = "xz", version = 2)
usethis::use_data(shp_hex_2021, overwrite = TRUE, compress = "xz", version = 2)
usethis::use_data(shp_hex_2023, overwrite = TRUE, compress = "xz", version = 2)
usethis::use_data(shp_hex_2025, overwrite = TRUE, compress = "xz", version = 2)
usethis::use_data(shp_hex_2027, overwrite = TRUE, compress = "xz", version = 2)

