#' @title Dotmap: Dodged CD centroids
#' @name dotmap
#' @description Shapefile of coordinates. Each row contains a coordinate of the centroid of the CD,
#'  slightly dodged so that points in dense places do not overlap.
#' @keywords internal
#'
#' @format Each object is for a particular congress. The year indicates the start
#'  of that Congress. Each observational is a congressional district, represented by
#'  a point.
#' @author Zoya Ahmer, Shiro Kuriwaki, Cory McCartan
#' @source Coordinates from 2012 onwards taken from US Census, `tigris` package.
#'  Coordinates from early Congresses taken from Jeffrey B. Lewis, historical congressional
#'  district shapefiles
#'
#' @examples
#' library(sf)
#' library(ggplot2)
#'
#' shp_dot_2023
#'
#' # plot points combined with state outline
#' shp_dot_2005 |>
#'   ggplot() +
#'   geom_sf(data = shp_states) +
#'   geom_sf(size = 1, alpha = 0.5)
#'
#' # can also use ggforce::geom_circle, extracting x,y coordinates from geom and
#' # setting a radius e.g. to 150000
#' @name shp_dot
NULL

#' @rdname shp_dot
"shp_dot_2005"
#' @rdname shp_dot
"shp_dot_2007"
#' @rdname shp_dot
"shp_dot_2009"
#' @rdname shp_dot
"shp_dot_2011"
#' @rdname shp_dot
"shp_dot_2013"
#' @rdname shp_dot
"shp_dot_2015"
#' @rdname shp_dot
"shp_dot_2017"
#' @rdname shp_dot
"shp_dot_2019"
#' @rdname shp_dot
"shp_dot_2021"
#' @rdname shp_dot
"shp_dot_2023"
#' @rdname shp_dot
"shp_dot_2025"

#' State map
#'
#' Shapefile of US states with Albers projection. Useful as an outline to dot maps of CDs.
#'
#' @seealso \link{shp_dot}
#' @source Alaska and Hawaii are modified following UrbanInstitute/urbnmapr
#'
#' @examples
#'  library(ggplot2)
#'  shp_states |>
#'    ggplot() +
#'    geom_sf() +
#'    geom_sf_text(aes(label = state))
"shp_states"

library(tidyverse)
library(sf)
library(tigris)
library(geomander) # for get_lewis
library(ccesMRPprep) # for to_cd. remotes::install_github("kuriwaki/ccesMRPprep")
library(glue)

# Parameters ----
proj_crs <- 5070
circ_radius <- 18000

# temporary download full shapefiles
if (!all(file.exists(glue("~/Downloads/tmp_shp_{109:119}.rds")))) {
  for (c in 109:112) {
    utils::data("state", package = "datasets", envir = environment())
    map_df(state_abb, \(x) geomander::get_lewis(state = x, congress = c), .progress = TRUE) |>
      write_rds(glue("~/Downloads/tmp_shp_{c}.rds"))
  }

  for (c in 113:118) {
    yr <- 2 * c + 1786 + 1
    tigris::congressional_districts(year = yr, cb = TRUE, resolution = "20m") |>
      write_rds(glue("~/Downloads/tmp_shp_{c}.rds"))
  }
  # 2024 shapefile for 119th
  # the standard year formula does not yet work for this session in `tigris`
  for (c in 119) {
    tigris::congressional_districts(year = 2024, cb = TRUE, resolution = "20m") |>
      write_rds(glue("~/Downloads/tmp_shp_{c}.rds"))
  }
}

#' Dodge centroids
#' @param source get from Lewis data or Census tigris
#' @param c congress number
#' @param cd_col unquoted name of the variable
shp_dot_func <- function(source = c("lewis", "census"),
                         c,
                         cd_col = NULL) {
  source <- match.arg(source)

  if (source == "lewis") {
    # get district shapefile for a state
    cd_sf <- read_rds(glue("~/Downloads/tmp_shp_{c}.rds")) |>
      mutate(geometry = st_make_valid(geometry)) |>
      st_transform(crs = proj_crs) |>
      rename(dist = district)
  }

  if (source == "census") {
    cd_sf <- read_rds(glue("~/Downloads/tmp_shp_{c}.rds")) |>
      mutate(geometry = st_make_valid(geometry)) |>
      # remove PR, territories
      filter(!STATEFP %in% c("72", "60", "66", "69", "78")) |>
      st_transform(crs = proj_crs) |>
      mutate(STATEFP = as.character(STATEFP)) |>
      left_join(
        tigris::fips_codes |>
          select(STATEFP = state_code, statename = state_name) |>
          distinct(),
        by = "STATEFP"
      ) |>
      mutate(dist = str_remove({{ cd_col }}, "^0+"))
  }
  # common operations
  centroids <- cd_sf |>
    filter(statename != "District of Columbia") |>
    mutate(
      cd = ccesMRPprep::to_cd(statename, dist),
      dist = NULL, statename = NULL,
      # fix entries for at large states in the census
      cd = sub("-NA$", "-01", cd)
    ) |>
    geomander::st_centerish() |>
    mutate(
      centroid = geometry,
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
  centroids <- centroids |>
    select(cd, geometry, x_opt, y_opt) |>
    arrange(cd) |>
    st_drop_geometry() |>
    st_as_sf(coords = c("x_opt", "y_opt"), crs = proj_crs)

  # add ak and hi and shift points to match map
  ak <- centroids[str_starts(centroids$cd, "AK"), ]
  hi <- centroids[str_starts(centroids$cd, "HI"), ]

  st_geometry(ak) <- st_geometry(ak) + c(1.15e6, -4.7e6)
  st_geometry(hi) <- st_geometry(hi) + c(5.23e6, -1.48e6)

  akhi_adjusted <- bind_rows(ak, hi)
  st_crs(akhi_adjusted) <- proj_crs

  centroids[str_starts(centroids$cd, "AK|HI"), ] <- akhi_adjusted

  centroids <- centroids |>
    mutate(cong = c, .before = 1)
}

# Run function to create dataset for each Congress ----
shp_dot_2005 <- shp_dot_func("lewis", 109)
shp_dot_2007 <- shp_dot_func("lewis", 110)
shp_dot_2009 <- shp_dot_func("lewis", 111)
shp_dot_2011 <- shp_dot_func("lewis", 112)
shp_dot_2013 <- shp_dot_func("census", 113, CD113FP)
shp_dot_2015 <- shp_dot_func("census", 114, CD114FP)
shp_dot_2017 <- shp_dot_func("census", 115, CD115FP)
shp_dot_2019 <- shp_dot_func("census", 116, CD116FP)
shp_dot_2021 <- shp_dot_func("census", 117, CD116FP)
shp_dot_2023 <- shp_dot_func("census", 118, CD118FP)
shp_dot_2025 <- shp_dot_func("census", 119, CD119FP)

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
usethis::use_data(shp_dot_2025, overwrite = TRUE, compress = "xz")
