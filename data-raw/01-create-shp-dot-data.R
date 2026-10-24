#' @name dotmap
#' @title Create dodged CD centroids

library(tidyverse)
library(sf)
library(glue)
library(fourthirtyfive)

# Use the working-tree Census reader shared with geographic maps.
source("R/load-cd-shps.R")

# Parameters ----
proj_crs <- 5070
circ_radius <- 18000

# Layout helper ----
dodge_updated_dots <- function(target_xy, updated, radius = 18000) {
  # Optimize only the updated dots; all other coordinates remain fixed.
  # Work in units of the dot radius for numerical stability.
  target_scaled <- target_xy / radius
  min_sep <- 2 * 1.02

  positions <- function(par) {
    xy <- target_scaled
    xy[updated, ] <- matrix(par, ncol = 2)
    xy
  }

  loss <- function(par) {
    xy <- positions(par)
    distances <- as.matrix(stats::dist(xy))
    overlap <- pmax(min_sep - distances, 0)
    sum((xy[updated, ] - target_scaled[updated, ])^2) +
      1000 * sum(overlap[upper.tri(overlap)]^2)
  }

  gradient <- function(par) {
    xy <- positions(par)
    distances <- as.matrix(stats::dist(xy))
    coefficients <- -2000 * pmax(min_sep - distances, 0) /
      pmax(distances, 1e-8)
    diag(coefficients) <- 0
    repulsion <- xy * rowSums(coefficients) - coefficients %*% xy
    as.vector(
      2 * (xy[updated, ] - target_scaled[updated, ]) + repulsion[updated, ]
    )
  }

  fit <- stats::optim(
    par = as.vector(target_scaled[updated, ]),
    fn = loss,
    gr = gradient,
    method = "L-BFGS-B",
    control = list(maxit = 1000, factr = 1e7, pgtol = 1e-7)
  )
  if (fit$convergence != 0L) {
    stop(glue::glue("Dot layout did not converge: {fit$message}"))
  }

  # Assign only updated rows so carried-forward coordinates stay identical.
  result <- target_xy
  result[updated, ] <- positions(fit$par)[updated, ] * radius
  distances <- as.matrix(stats::dist(result))
  diag(distances) <- Inf
  if (any(distances[updated, , drop = FALSE] < 2 * radius)) {
    stop("The updated dots still overlap at the 18 km dot radius.")
  }
  result
}

#' Dodge centroids
#' @param source get from Lewis data or Census tigris
#' @param c congress number
#' @param previous Optional previous dot map; retain its dots outside redrawn states
shp_dot_func <- function(source = c("lewis", "census"),
                         c,
                         previous = NULL) {
  source <- match.arg(source)
  if (c == 120 && is.null(previous)) {
    stop("Supply the 2025 dot map as `previous` when building 2027.")
  }

  if (source == "lewis") {
    cache_path <- glue("~/Downloads/tmp_shp_{c}.rds")
    districts_raw <- if (file.exists(cache_path)) {
      read_rds(cache_path)
    } else {
      map_df(datasets::state.abb, \(state) geomander::get_lewis(state = state, congress = c))
    }
    cd_sf <- districts_raw |>
      st_make_valid() |>
      st_transform(proj_crs) |>
      filter(statename != "District of Columbia") |>
      transmute(cd = ccesMRPprep::to_cd(statename, district))
  } else {
    cd_sf <- get_census_cd_sf(c)
  }
  # common operations
  centroids <- cd_sf |>
    mutate(cd = sub("-NA$", "-01", cd)) |>
    geomander::st_centerish(epsg = proj_crs) |>
    mutate(
      centroid = geometry,
      x = st_coordinates(centroid)[, 1],
      y = st_coordinates(centroid)[, 2],
      radius = circ_radius
    )

  if (!is.null(previous)) {
    # For 2027, move only districts in the nine redrawn states. Missouri,
    # Alaska, Hawaii, and every other unchanged state's dots stay fixed.
    updated <- substr(previous$cd, 1, 2) %in% redrawn_states_2027
    stopifnot(c == 120, st_crs(previous)$epsg == proj_crs,
              !anyDuplicated(centroids$cd), setequal(centroids$cd, previous$cd))
    target_xy <- st_coordinates(previous)
    target_xy[updated, ] <- st_coordinates(centroids)[match(previous$cd[updated], centroids$cd), ]
    stopifnot(all(is.finite(target_xy)))
    layout_xy <- dodge_updated_dots(target_xy, updated, radius = circ_radius)
    result <- previous |> mutate(cong = c)
    st_geometry(result)[updated] <- st_geometry(st_as_sf(
      data.frame(x = layout_xy[updated, 1], y = layout_xy[updated, 2]),
      coords = c("x", "y"), crs = proj_crs
    ))
    stopifnot(nrow(result) == 435L,
              identical(st_geometry(result)[!updated], st_geometry(previous)[!updated]))
    return(result)
  }

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
  dot_points <- centroids |>
    select(cd, geometry, x_opt, y_opt) |>
    arrange(cd) |>
    st_drop_geometry() |>
    st_as_sf(coords = c("x_opt", "y_opt"), crs = proj_crs)

  # add ak and hi and shift points to match map
  ak <- dot_points[str_starts(dot_points$cd, "AK"), ]
  hi <- dot_points[str_starts(dot_points$cd, "HI"), ]

  st_geometry(ak) <- st_geometry(ak) + c(1.15e6, -4.7e6)
  st_geometry(hi) <- st_geometry(hi) + c(5.23e6, -1.48e6)

  akhi_adjusted <- bind_rows(ak, hi)
  st_crs(akhi_adjusted) <- proj_crs

  dot_points[str_starts(dot_points$cd, "AK|HI"), ] <- akhi_adjusted

  dot_points |>
    mutate(cong = c, .before = 1)
}

# Run function to create dataset for each Congress ----
shp_dot_2005 <- shp_dot_func("lewis", 109)
shp_dot_2007 <- shp_dot_func("lewis", 110)
shp_dot_2009 <- shp_dot_func("lewis", 111)
shp_dot_2011 <- shp_dot_func("lewis", 112)
shp_dot_2013 <- shp_dot_func("census", 113)
shp_dot_2015 <- shp_dot_func("census", 114)
shp_dot_2017 <- shp_dot_func("census", 115)
shp_dot_2019 <- shp_dot_func("census", 116)
shp_dot_2021 <- shp_dot_func("census", 117)
shp_dot_2023 <- shp_dot_func("census", 118)
shp_dot_2025 <- shp_dot_func("census", 119)
shp_dot_2027 <- shp_dot_func("census", 120, previous = shp_dot_2025)

# Write ----
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
usethis::use_data(shp_dot_2027, overwrite = TRUE, compress = "xz")
