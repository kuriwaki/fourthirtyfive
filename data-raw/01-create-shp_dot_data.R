# Create datasets for dot maps for each Congress 2006-2024
# Pull congressional districts maps for 2006-2024 and create a dot sf map

library(tidyverse)
library(sf)
library(dplyr)
library(purrr)
library(geomander)
library(ggplot2)
library(rmapshaper)
library(tigris)
library(ccesMRPprep)
library(glue)
options(tigris_use_cache = TRUE)

# Parameters ----
states <- c(state.abb)
proj_crs <- 5070
circ_radius <- 17000


# temporary download full shapefiles
if (!all(file.exists(glue("~/Downloads/tmp_shp_{109:118}.rds")))) {
  for (c in 109:112) {
    map_df(states, \(x) geomander::get_lewis(state = x, congress = c), .progress = TRUE) |>
      write_rds(glue("~/Downloads/tmp_shp_{c}.rds"))
  }

  for (c in 113:118) {
    yr = 2*c + 1786 + 1
    tigris::congressional_districts(year = yr, cb = TRUE, resolution = "20m") |>
      write_rds(glue("~/Downloads/tmp_shp_{c}.rds"))
  }
}


# Function to generate geographic congressional data from `geomander` OR
# geographic congressional data from census
#' @param c congress number
#' @param cd_col unquoted name of the variable
shp_dot_func <- function(source = c("geomander", "census"),
                         c,
                         cd_col = NULL) {
  source <- match.arg(source)

  if (source == "geomander") {
    # get district shapefile for a state
    cd_sf <- read_rds(glue("~/Downloads/tmp_shp_{c}.rds")) |>
      mutate(geometry = st_make_valid(geometry)) |>
      # filter out AK/HI for now to make it easier to map
      filter(!statename %in% c("Alaska", "Hawaii")) |>
      st_transform(crs = proj_crs) |>
      as.data.frame() |>
      rename(dist = district)

  }

  if (source == "census") {
    cd_sf <- read_rds(glue("~/Downloads/tmp_shp_{c}.rds")) |>
      mutate(geometry = st_make_valid(geometry)) |>
      # remove AK, HI, PR, territories for now to make it easier to map
      filter(!STATEFP %in% c("02", "15", "72", "60", "66", "69", "78")) |>
      st_transform(crs = proj_crs) |>
      mutate(STATEFP = as.character(STATEFP)) |>
      left_join(
        tigris::fips_codes |>
          select(STATEFP = state_code, statename = state_name) |>
          distinct(),
        by = "STATEFP"
      ) |>
      mutate(dist = str_remove({{cd_col}}, "^0+"))
  }

  # common operations
  centroids <- cd_sf |>
    filter(statename != "District of Columbia") |>
    mutate(cd = to_cd(statename, dist),
           dist = NULL, statename = NULL) |>
    mutate(
      centroid = st_centroid(geometry),
      x = st_coordinates(centroid)[, 1],
      y = st_coordinates(centroid)[, 2],
      radius = circ_radius
    )

  # layout optimization and layout cost function to minimize overlap and
  # total displacement.
  # circles overlap on the map if not used
  # optimization written by Cory McCartan
  coords <- as.matrix(st_drop_geometry(centroids)[, c("x", "y")])
  radii <- centroids$radius
  mean_sep <- mean(as.matrix(dist(coords)))
  sep_mat <- outer(radii, radii, `+`) * 1.02
  diag(sep_mat) <- 0

  fn <- function(pos) {
    xy <- matrix(pos, ncol = 2)
    dm <- as.matrix(dist(xy))
    pen <- sum((pmax(sep_mat - dm, 0))^2) / mean_sep^2
    disp <- mean(sqrt(rowSums((xy - coords)^2))) / mean_sep
    ## final cost = displacement + 10×penalty
    disp + 10 * pen
  }

  # method is "L-BFGS-B" instead of "Nelder-Mead" b/c of large amt of data
  cli::cli_progress_message("Starting force directed algorithm")
  tictoc::tic()
  res <- optim(coords, fn, method = "L-BFGS-B", control = list(
    maxit = 1e2, factr = 1e10, parscale = rep(circ_radius, length(coords))
  ))
  tictoc::toc()

  xy_opt <- matrix(res$par, ncol = 2)
  centroids$x_opt <- xy_opt[, 1]
  centroids$y_opt <- xy_opt[, 2]

  # want point geometry
  # only need certain variables to map
  centroids |>
    select(cd, geometry, x_opt, y_opt) |>
    arrange(cd) |>
    st_drop_geometry() |>
    st_as_sf(coords = c("x_opt", "y_opt"), crs = proj_crs)
}

# Run function to create dataset for each Congress ----
shp_dot_2005 <- shp_dot_func("geomander", 109)
shp_dot_2007 <- shp_dot_func("geomander", 110)
shp_dot_2009 <- shp_dot_func("geomander", 111)
shp_dot_2011 <- shp_dot_func("geomander", 112)
shp_dot_2013 <- shp_dot_func("census", 113, CD113FP)
shp_dot_2015 <- shp_dot_func("census", 114, CD114FP)
shp_dot_2017 <- shp_dot_func("census", 115, CD115FP)
shp_dot_2019 <- shp_dot_func("census", 116, CD116FP)
shp_dot_2021 <- shp_dot_func("census", 117, CD116FP)
shp_dot_2023 <- shp_dot_func("census", 118, CD118FP)

# Write ---
usethis::use_data(shp_dot_2005, overwrite = TRUE, compress = "xz")
usethis::use_data(shp_dot_2007, overwrite = TRUE, compress = "xz")
usethis::use_data(shp_dot_2009, overwrite = TRUE, compress = "xz")
usethis::use_data(shp_dot_2011, overwrite = TRUE, compress = "xz")
usethis::use_data(shp_dot_2013, overwrite = TRUE, compress = "xz")
usethis::use_data(shp_dot_2015, overwrite = TRUE, compress = "xz")
usethis::use_data(shp_dot_2017, overwrite = TRUE, compress = "xz")
usethis::use_data(shp_dot_2019, overwrite = TRUE, compress = "xz")
usethis::use_data(shp_dot_2021, overwrite = TRUE, compress = "xz")
usethis::use_data(shp_dot_2023, overwrite = TRUE, compress = "xz")

# separate state function
shp_state <- tigris::states(cb = TRUE, resolution = "20m") |>
  select(statename = NAME, state = STUSPS, geometry) |>
  filter(!state %in% c("HI", "AK", "PR")) |>
  arrange(state) |>
  st_transform(crs = proj_crs)
usethis::use_data(shp_state, overwrite = TRUE, compress = "xz")


