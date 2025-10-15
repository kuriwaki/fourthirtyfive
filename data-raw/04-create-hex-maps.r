library(ccesMRPprep)
library(tidyverse)
library(glue)
library(patchwork)
library(usethis)
library(sf)

# election data
cd_info_2018
cd_info_2020
cd_info_2022
cd_info_2024

# raw shps
# can download these shps from The Downballot maps database
# https://docs.google.com/spreadsheets/d/13XkF59JKzvw4SeSq5mbgIFrJfYjK4amg9JoQE5e9grQ/edit?gid=1250379179#gid=1250379179
cd_shp_2019 <- read_sf("data-raw/hexmap_2018/HexCDv20/")
cd_shp_2021 <- read_sf("data-raw/hexmap_2020/HexCDv21/")
cd_shp_2023 <- read_sf("data-raw/hexmap_2022/HexCDv30/")
cd_shp_2025 <- read_sf("data-raw/hexmap_2024/HexCDv31/")

# map_crs <- function(crs, data = cd_shp) {
#   st_crs(data) <- crs
#   ggplot(data) + geom_sf() +
#     theme_bw() +
#     labs(title = glue("CRS: {crs}")) +
#     theme(plot.title = element_text(hjust = 0.5, face = "bold"))
# }
#
# map_crs(4326) + map_crs(3857) + map_crs(4328) + map_crs(3857) +
#   plot_layout(nrow = 2, widths = c(0.5, 0.5))

shp_hex_2019 <- cd_shp_2019 |>
  mutate(cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
         cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")) |>
  relocate(cd)

shp_hex_2021 <- cd_shp_2021 |>
  mutate(cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
         cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")) |>
  relocate(cd)


shp_hex_2023 <- cd_shp_2023 |>
  mutate(cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
         cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")) |>
  relocate(cd)

shp_hex_2025 <- cd_shp_2025 |>
  mutate(cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
         cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")) |>
  relocate(cd)

usethis::use_data(shp_hex_2019, overwrite = TRUE)
usethis::use_data(shp_hex_2021, overwrite = TRUE)
usethis::use_data(shp_hex_2023, overwrite = TRUE)
usethis::use_data(shp_hex_2025, overwrite = TRUE)
