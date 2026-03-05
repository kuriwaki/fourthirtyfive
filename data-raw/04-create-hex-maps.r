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

shp_hex_2019 <- cd_shp_2019 |>
  transmute(
    cong = 116,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd)

shp_hex_2021 <- cd_shp_2021 |>
  transmute(
    cong = 117,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd)

shp_hex_2023 <- cd_shp_2023 |>
  transmute(
    cong = 118,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd)

shp_hex_2025 <- cd_shp_2025 |>
  transmute(
    cong = 119,
    cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
    cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")
  ) |>
  arrange(cd)

## Use older version for now
shp_hex_2015 <- shp_hex_2019 |>
  mutate(cong = 114)
shp_hex_2017 <- shp_hex_2019 |>
  mutate(cong = 115)

usethis::use_data(shp_hex_2015, overwrite = TRUE)
usethis::use_data(shp_hex_2017, overwrite = TRUE)
usethis::use_data(shp_hex_2019, overwrite = TRUE)
usethis::use_data(shp_hex_2021, overwrite = TRUE)
usethis::use_data(shp_hex_2023, overwrite = TRUE)
usethis::use_data(shp_hex_2025, overwrite = TRUE)

