# remotes::install_github("kuriwaki/ccesMRPprep")
library(ccesMRPprep)
library(tidyverse)
library(glue)
library(patchwork)
library(usethis)
library(sf)

# raw shps
# can download these shps from The Downballot maps database
# https://docs.google.com/spreadsheets/d/13XkF59JKzvw4SeSq5mbgIFrJfYjK4amg9JoQE5e9grQ/edit?gid=1250379179#gid=1250379179
cd_shp_2019 <- cd_shp_2021 <- read_sf("data-raw/hexmap_2020/HexCDv21wm/")
cd_shp_2023 <- read_sf("data-raw/hexmap_2022/HexCDv30wm/")
cd_shp_2025 <- read_sf("data-raw/hexmap_2024/HexCDv31wm/")

cd_shp_hex_2019 <- cd_shp_2019 |>
  transmute(
    cong = 116,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd)

cd_shp_hex_2021 <- cd_shp_2021 |>
  transmute(
    cong = 117,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd)

cd_shp_hex_2023 <- cd_shp_2023 |>
  transmute(
    cong = 118,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd)

cd_shp_hex_2025 <- cd_shp_2025 |>
  mutate(STATEAB = if_else(STATEAB == "01", "AL", STATEAB)) |>
  transmute(
    cong = 119,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd)

## Use older version for now
### Between the 2012-14 and 2016 data, FL, NC, VA changed their districts
### Between the 2016 and 2018 data, PA changed their districts
cd_shp_hex_2013 <- cd_shp_hex_2019 |>
  mutate(cong = 113)
cd_shp_hex_2015 <- cd_shp_hex_2019 |>
  mutate(cong = 114)
cd_shp_hex_2017 <- cd_shp_hex_2019 |>
  mutate(cong = 115)

usethis::use_data(cd_shp_hex_2013, overwrite = TRUE)
usethis::use_data(cd_shp_hex_2015, overwrite = TRUE)
usethis::use_data(cd_shp_hex_2017, overwrite = TRUE)
usethis::use_data(cd_shp_hex_2019, overwrite = TRUE)
usethis::use_data(cd_shp_hex_2021, overwrite = TRUE)
usethis::use_data(cd_shp_hex_2023, overwrite = TRUE)
usethis::use_data(cd_shp_hex_2025, overwrite = TRUE)

