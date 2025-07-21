# Create datasets for dot maps for each Congress 2006-2024

# Pull congressional districts maps for 2006-2024 and create a dot sf map

# `cong_lewis` function: Use geomander/get_lewis for cd for 109th and 110th
# congress (2005 and 2007) b/c there is no census data before 2010.

# `congcen` function: Use census data for congressional district for 112th,
# 114th, 116th, 118th congresses (2011-2023).

# Load libraries ----
library(tidyverse)
library(sf)
library(dplyr)
library(purrr)
library(geomander)
library(ggforce)
library(ggplot2)
library(cdlTools)
library(tigris)
options(tigris_use_cache = TRUE)

# Parameters ----
states <- c(state.abb)
proj_crs <- 5070
# circles are not the same size without fixing the radius
circ_radius <- 15000

# Function to generate geographic congressional data from `geomander` ----
cong_lewis <- function(cong_ses, title_lbl, name) {
  # get district shapefile for a state
  lewis_sf <- map_df(states, function(st) {
    tryCatch(
      {
        get_lewis(state = st, congress = cong_ses)
      },
      error = function(e) {
        message(paste("Error fetching:", st))
        NULL
      }
    )
  })

  lewis_sf <- lewis_sf |>
    mutate(geometry = st_make_valid(geometry)) |>
    # filter out AK/HI for now to make it easier to map
    filter(!statename %in% c("Alaska", "Hawaii")) |>
    st_transform(crs = proj_crs) |>
    rename(cd = district)

  # compute centroids
  # uniform radius so that circles are the same size
  centroids <- lewis_sf |>
    mutate(
      centroid = st_centroid(geometry),
      x = st_coordinates(centroid)[, 1],
      y = st_coordinates(centroid)[, 2],
      radius = circ_radius
    )

  # layout optimization and layout cost function to minimize overlap and
  # total displacement.
  # circles overlap on the map if not used
  # see mccartan's circles
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

  parscale <- rep(mean_sep, length(coords))
  # method is "L-BFGS-B" instead of "Nelder-Mead" b/c of large amt of data
  res <- optim(coords, fn, method = "L-BFGS-B", control = list(
    maxit = 1e5, reltol = 1e-8, parscale = parscale
  ))

  xy_opt <- matrix(res$par, ncol = 2)
  centroids$x_opt <- xy_opt[, 1]
  centroids$y_opt <- xy_opt[, 2]

  # only need certain variables to map
  centroids <- centroids |>
    select(cd, statename, geometry, radius, x_opt, y_opt)

  return(centroids)

  assign(name, centroids, envir = .GlobalEnv)
}

# Function to generate geographic congressional data from census ----
# Similar code to above function
cong_cen <- function(cong_year, title_lbl, name) {
  # get district shapefile for a state
  cd <- congressional_districts(year = cong_year)

  cd <- cd |>
    mutate(geometry = st_make_valid(geometry)) |>
    # remove AK, HI, PR, territories for now to make it easier to map
    filter(!STATEFP %in% c("02", "15", "72", "60", "66", "69", "78")) |>
    st_transform(crs = proj_crs)

  centroids <- cd |>
    mutate(
      centroid = st_centroid(geometry),
      x = st_coordinates(centroid)[, 1],
      y = st_coordinates(centroid)[, 2],
      radius = circ_radius
    )

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
    disp + 10 * pen
  }

  res <- optim(coords, fn, method = "L-BFGS-B", control = list(
    maxit = 1e5, reltol = 1e-8, parscale = rep(circ_radius, length(coords))
  ))

  xy_opt <- matrix(res$par, ncol = 2)
  centroids$x_opt <- xy_opt[, 1]
  centroids$y_opt <- xy_opt[, 2]

  # match census dataset columns to the geomander dataset
  centroids$statename <- sapply(centroids$STATEFP,
                                function(x) fips(x, to = "Name"))

  centroids <- centroids |>
    mutate(cd = sub("^0+(\\d)$", "\\1", CD112FP)) |>
    select(cd, statename, geometry, radius, x_opt, y_opt)

  return(centroids)

  assign(name, centroids, envir = .GlobalEnv)
}

# Run function to create dataset for each Congress ----
shp_dot_2005 <- cong_lewis(109, "109th Congress", "shp_dot_2005")
shp_dot_2007 <- cong_lewis(110, "110th Congress", "shp_dot_2007")
shp_dot_2009 <- cong_lewis(111, "111th Congress", "shp_dot_2009")
shp_dot_2011 <- cong_cen(2011, "112th Congress", "shp_dot_2011")
shp_dot_2013 <- cong_cen(2013, "113th Congress", "shp_dot_2013")
shp_dot_2015 <- cong_cen(2015, "114th Congress", "shp_dot_2015")
shp_dot_2017 <- cong_cen(2017, "115th Congress", "shp_dot_2015")
shp_dot_2019 <- cong_cen(2019, "116th Congress", "shp_dot_2019")
shp_dot_2021 <- cong_cen(2021, "117th Congress", "shp_dot_2021")
shp_dot_2023 <- cong_cen(2023, "118th Congress", "shp_dot_2023")

# To plot data ----
## states_map <- tigris::states(cb = TRUE, resolution = "20m") |>
## filter(STUSPS %in% states & !STUSPS %in% c("AK", "HI")) |>
## st_transform(crs = proj_crs)

## p <- ggplot() +
## geom_sf(data = states_map, fill = "#d7e8ee", color = "white", size = 0.3) +
### shp_dot_2009, shp_dot_2011, etc...
## geom_circle(data = shp_dot_2005,
## aes(x0 = x_opt, y0 = y_opt, r = radius),
## fill = "darkblue", color = NA, alpha = 0.9) +
## coord_sf(crs = proj_crs) +
## theme_void() +
## labs(title = title_lbl)

# Write ---
usethis::use_data(shp_dot_2005, overwrite = TRUE)
usethis::use_data(shp_dot_2007, overwrite = TRUE)
usethis::use_data(shp_dot_2009, overwrite = TRUE)
usethis::use_data(shp_dot_2011, overwrite = TRUE)
usethis::use_data(shp_dot_2013, overwrite = TRUE)
usethis::use_data(shp_dot_2015, overwrite = TRUE)
usethis::use_data(shp_dot_2017, overwrite = TRUE)
usethis::use_data(shp_dot_2019, overwrite = TRUE)
usethis::use_data(shp_dot_2021, overwrite = TRUE)
usethis::use_data(shp_dot_2023, overwrite = TRUE)
