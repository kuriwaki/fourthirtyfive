# Create datasets for dot maps for each Congress 2006-2024

# Pull congressional districts maps for 2006-2024 and create a dot sf map

# `shp_dot_func` function:

# *First part uses  geomander/get_lewis for cd for 109th and 110th
# congress (2005 and 2007) b/c there is no census data before 2010.

# *Second part uses census data for congressional district for 112th,
# 114th, 116th, 118th congresses (2011-2023).

# Load libraries ----
library(tidyverse)
library(sf)
library(dplyr)
library(purrr)
library(geomander)
library(ggplot2)
library(rmapshaper)
library(tigris)
options(tigris_use_cache = TRUE)

# Parameters ----
states <- c(state.abb)
proj_crs <- 5070
circ_radius <- 15000

# Function to generate geographic congressional data from `geomander` OR
# geographic congressional data from census
shp_dot_func <- function(source = c("geomander", "census"),
                         ses_or_year,
                         cd_lbl = NULL) {
  source <- match.arg(source)

  if (source == "geomander") {
    # get district shapefile for a state
    lewis_sf <- map_df(states, function(st) {
      tryCatch(
        {
          get_lewis(state = st, congress = ses_or_year)
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
    centroids <- lewis_sf |>
      mutate(
        centroid = st_centroid(geometry),
        x = st_coordinates(centroid)[, 1],
        y = st_coordinates(centroid)[, 2],
        radius = circ_radius
      )

  } else if (source == "census") {
    cd <- congressional_districts(year = ses_or_year, cb = TRUE)

    cd <- cd |>
      mutate(geometry = st_make_valid(geometry)) |>
      # remove AK, HI, PR, territories for now to make it easier to map
      filter(!STATEFP %in% c("02", "15", "72", "60", "66", "69", "78")) |>
      st_transform(crs = proj_crs)

    # match census dataset columns to the geomander dataset
    cd <- cd |> mutate(STATEFP = as.character(STATEFP))
    cd <- cd |>
      left_join(
        tigris::fips_codes |>
          select(STATEFP = state_code, statename = state_name) |>
          distinct(),
        by = "STATEFP"
      )

    stopifnot(!is.null(cd_lbl))

    cd <- cd |>
      mutate(cd = sub("^0+", "", .data[[cd_lbl]]))

    centroids <- cd |>
      mutate(
        centroid = st_centroid(geometry),
        x = st_coordinates(centroid)[, 1],
        y = st_coordinates(centroid)[, 2],
        radius = circ_radius
      )
  }

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

  # method is "L-BFGS-B" instead of "Nelder-Mead" b/c of large amt of data
  res <- optim(coords, fn, method = "L-BFGS-B", control = list(
    maxit = 1e1, factr = 1e-8, parscale = rep(circ_radius, length(coords))
  ))

  xy_opt <- matrix(res$par, ncol = 2)
  centroids$x_opt <- xy_opt[, 1]
  centroids$y_opt <- xy_opt[, 2]

  # want point geometry
  # only need certain variables to map
  centroids <- centroids |>
    select(cd, statename, x_opt, y_opt) |>
    mutate(geom_poly = geometry) |>
    select(cd, statename, geom_poly, x_opt, y_opt) |>
    st_drop_geometry() |>
    st_as_sf(coords = c("x_opt", "y_opt"), crs = proj_crs) |>
    mutate(geom_poly = rmapshaper::ms_simplify(geom_poly))

  return(centroids)
}

# Run function to create dataset for each Congress ----
shp_dot_2005 <- shp_dot_func("geomander", 109)
shp_dot_2007 <- shp_dot_func("geomander", 110)
shp_dot_2009 <- shp_dot_func("geomander", 111)
shp_dot_2011 <- shp_dot_func("geomander", 112)
shp_dot_2013 <- shp_dot_func("census", 2013, "CD113FP")
shp_dot_2015 <- shp_dot_func("census", 2015, "CD114FP")
shp_dot_2017 <- shp_dot_func("census", 2017, "CD115FP")
shp_dot_2019 <- shp_dot_func("census", 2019, "CD116FP")
# shows 116th Congress on the census
shp_dot_2021 <- shp_dot_func("census", 2021, "CD116FP")
shp_dot_2023 <- shp_dot_func("census", 2023, "CD118FP")

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
