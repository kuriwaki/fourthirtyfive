#' @title State map
#' @name cd_shp_states
#'
#' Shapefile of US states with Albers projection. Useful as an outline to dot maps of CDs.
#'
#' @seealso \link{cd_shp_dot}
#' @source Alaska and Hawaii are modified following UrbanInstitute/urbnmapr
#'
#' @examples
#' library(ggplot2)
#' cd_shp_states |>
#'   ggplot() +
#'   geom_sf() +
#'   geom_sf_text(aes(label = state))
"cd_shp_states"

library(tidyverse)
library(tigris)
library(sf)
library(urbnmapr)

# Parameters ----
proj_crs <- 5070

# 48 states
cd_shp_states <- tigris::states(cb = TRUE, resolution = "20m") |>
  select(statename = NAME, state = STUSPS, geometry) |>
  filter(!state %in% c("HI", "AK", "PR")) |>
  arrange(state) |>
  st_transform(crs = proj_crs)

# AK and HI
urbn_sf <- urbnmapr::get_urbn_map(map = "states", sf = TRUE)
akhi <- urbn_sf[50:51, ] |>
  select(cd = state_abbv, geometry) |>
  st_geometry() # reduce to just the geometry column
st_crs(akhi) <- 5070

# shift and rotate
akhi_sf <- tibble(
  state = c("AK", "HI"),
  geometry = c(
    akhi[1, ] + c(-0.3e6, 2.5e6),
    (akhi[2, ] + c(-0.15e6, 2.26e6)) * rot(pi / 16) * 1.2
  )
) |>
  st_sf(crs = 5070) |>
  mutate(geometry = st_simplify(geometry)) |>
  mutate(statename = c("Alaska", "Hawaii"))


# combine
cd_shp_states <- cd_shp_states |>
  bind_rows(akhi_sf)

usethis::use_data(cd_shp_states, overwrite = TRUE, compress = "xz")
