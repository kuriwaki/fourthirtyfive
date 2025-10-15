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
st_shp_2018 <- read_sf("data-raw/hexmap_2018/HexSTv20/")
cd_shp_2018 <- read_sf("data-raw/hexmap_2018/HexCDv20/")

st_shp_2020 <- read_sf("data-raw/hexmap_2020/HexSTv20/")
cd_shp_2020 <- read_sf("data-raw/hexmap_2020/HexCDv21/")

st_shp_2022 <- read_sf("data-raw/hexmap_2022/HexSTv30/")
cd_shp_2022 <- read_sf("data-raw/hexmap_2022/HexCDv30/")

st_shp_2024 <- read_sf("data-raw/hexmap_2024/HexSTv30/")
cd_shp_2024 <- read_sf("data-raw/hexmap_2024/HexCDv31/")

st_crs(st_shp_2018) <- 3857
# twice for warning message
st_crs(st_shp_2018) <- 3857

st_crs(st_shp_2020) <- 3857
st_crs(st_shp_2020) <- 3857

st_crs(st_shp_2022) <- 3857
st_crs(st_shp_2022) <- 3857

st_crs(st_shp_2024) <- 3857
st_crs(st_shp_2024) <- 3857

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

shp_hex_2018 <- cd_shp_2018 |>
  mutate(cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
         cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")) |>
  relocate(cd)

shp_hex_2020 <- cd_shp_2020 |>
  mutate(cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
         cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")) |>
  relocate(cd)


shp_hex_2022 <- cd_shp_2022 |>
  mutate(cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
         cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")) |>
  relocate(cd)

shp_hex_2024 <- cd_shp_2024 |>
  mutate(cd = glue("{STATEAB}-{str_pad(CDLABEL, width = 2, pad = '0')}"),
         cd = str_replace(cd, "-[A-Z][A-Z]$", "-01")) |>
  relocate(cd)

usethis::use_data(st_shp_2018, overwrite = TRUE)
usethis::use_data(st_shp_2020, overwrite = TRUE)
usethis::use_data(st_shp_2022, overwrite = TRUE)
usethis::use_data(st_shp_2024, overwrite = TRUE)
usethis::use_data(shp_hex_2018, overwrite = TRUE)
usethis::use_data(shp_hex_2020, overwrite = TRUE)
usethis::use_data(shp_hex_2022, overwrite = TRUE)
usethis::use_data(shp_hex_2024, overwrite = TRUE)
