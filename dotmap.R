# task: pull 2008, 2012, 2016, 2020, 2024 maps and create a dot map for cd

# LOAD LIBRARIES ---------------------------------------------------------------
library(sf)
library(dplyr)
library(ggplot2)
library(purrr)
library(geomander)
library(ggforce)
library(tigris)
options(tigris_use_cache = TRUE)

# use geomander/get_lewis for cd for 110th congress b/c no census data before 2010
# use census data for cd for 112th, 114th, 116th, 118th congress

# PARAMETERS -------------------------------------------------------------------
# 50 states
states <- c(state.abb)
# use Albers Equal Area CRS for continental U.S.
proj_crs <- 5070
# radius of each dot (in meters) so that they are all the same size
circ_radius <- 15000

# FUNCTION TO GENERATE PLOT FOR A CONGRESS FROM GEOMANDER ----------------------
congress_plot_lewis <- function(cong_ses, title_lbl) {
  # get district shapefile for a state
  lewis_sf <- map_df(states, function(st) {
    tryCatch({
      get_lewis(state = st, congress = cong_ses)
    }, error = function(e) {
      # skip states with errors
      message(paste("Error fetching:", st))
      NULL
    })
  })

  # clean lewis_sf
  lewis_sf <- lewis_sf %>%
    # clean geometries
    ## fix invalid geometries
    mutate(geometry = st_make_valid(geometry)) %>%
    # filter out AK/HI for now to make it easier to map
    filter(!statename %in% c("Alaska", "Hawaii")) %>%
    # project to albers CRS
    st_transform(crs = proj_crs) %>%
    # rename to merge easier
    rename(cd = district)

  # compute centroids
  # uniform radius so that circles are the same size
  centroids <- lewis_sf %>%
    mutate(centroid = st_centroid(geometry),
           # x coord
           x = st_coordinates(centroid)[,1],
           # y coord
           y = st_coordinates(centroid)[,2],
           # fixed radius for circles
           radius = circ_radius)

  # layout optimization
  # adapted from mccartan's circles
  # og coords
  coords <- as.matrix(st_drop_geometry(centroids)[, c("x", "y")])
  # constant radius
  radii <- centroids$radius
  # mean dist
  mean_sep <- mean(as.matrix(dist(coords)))
  # separation matrix
  ## represents the minimum distance needed between circle centers to avoid overlap
  sep_mat <- outer(radii, radii, `+`) * 1.02
  # sets diagonal to zero (a circle doesn't need separation from itself)
  diag(sep_mat) <- 0

  # layout cost function: minimize overlap and total displacement
  # adapted from mccartan's circles
  fn <- function(pos) {
    xy <- matrix(pos, ncol = 2)
    ## distances between all circle centers at current positions
    dm <- as.matrix(dist(xy))
    ## finds overlap amounts
    ## pen squares the overlaps and sums them (heavily penalizes any overlap)
    pen <- sum((pmax(sep_mat - dm, 0))^2) / mean_sep^2
    ## measures how far circles moved from original positions
    disp <- mean(sqrt(rowSums((xy - coords)^2))) / mean_sep
    ## final cost = displacement + 10×penalty (overlap is 10× more important than movement)
    disp + 10 * pen
  }

  # run optimization to minimize overlap
  # adapted from mccartan's circles
  ## scaling hint for optimizer
  ### parscale tells the optimizer the typical scale of changes (helps it take appropriate step sizes)
  parscale <- rep(mean_sep, length(coords))
  ### creates a vector of scaling hints for each coordinate
  #### optim runs the optimization starting from original coordinates
  #### optim returns the best positions it found
  res <- optim(coords, fn, method = "L-BFGS-B", control = list(
    ## run optimization
    maxit = 1e5, reltol = 1e-8, parscale = parscale))

  # assign optimized positions to centroids
  # adapted from mccartan's circles
  ## contains the optimized coordinates as a flat vector
  ## reshapes back to xy pairs
  xy_opt <- matrix(res$par, ncol = 2)
  ## stores optimized x and y coordinates in new columns
  centroids$x_opt <- xy_opt[, 1]
  centroids$y_opt <- xy_opt[, 2]

  # load U.S. mainland states shapefile for background map
  # not including AK and HI yet for simplicity
  ## state background map using tigris
  ### tigris uses geometries for US Census data
  states_map <- tigris::states(cb = TRUE, resolution = "20m") %>%
    filter(STUSPS %in% states & !STUSPS %in% c("AK", "HI")) %>%
    st_transform(crs = proj_crs)

  # plot
  p <- ggplot() +
    # map
    geom_sf(data = states_map, fill = "#d7e8ee", color = "white", size = 0.3) +
    # circles
    geom_circle(data = centroids,
                aes(x0 = x_opt, y0 = y_opt, r = radius),
                fill = "darkblue", color = NA, alpha = 0.9) +
    coord_sf(crs = proj_crs) +
    theme_void() +
    labs(title = title_lbl)

  return(p)
}

# FUNCTION TO GENERATE PLOT FOR A CONGRESS FROM CENSUS -------------------------
congress_plot_cen <- function(cong_year, title_lbl) {
  # get district shapefile for a state
  cd <- congressional_districts(year = cong_year)

  # clean lewis_sf
  cd <- cd %>%
    # clean geometries
    ## fix invalid geometries
    mutate(geometry = st_make_valid(geometry)) %>%
    # remove AK, HI, PR, territories for now to make it easier to map
    filter(!STATEFP %in% c("02", "15", "72", "60", "66", "69", "78")) %>%
    # project to albers CRS
    st_transform(crs = proj_crs)

  # compute centroids
  # uniform radius so that circles are the same size
  centroids <- cd %>%
    mutate(centroid = st_centroid(geometry),
           # x coord
           x = st_coordinates(centroid)[,1],
           # y coord
           y = st_coordinates(centroid)[,2],
           # fixed radius for circles
           radius = circ_radius)

  # layout optimization
  # adapted from mccartan's circles
  # og coords
  coords <- as.matrix(st_drop_geometry(centroids)[, c("x", "y")])
  # constant radius
  radii <- centroids$radius
  # mean dist
  mean_sep <- mean(as.matrix(dist(coords)))
  # separation matrix
  ## represents the minimum distance needed between circle centers to avoid overlap
  sep_mat <- outer(radii, radii, `+`) * 1.02
  # sets diagonal to zero (a circle doesn't need separation from itself)
  diag(sep_mat) <- 0

  # layout cost function: minimize overlap and total displacement
  # adapted from mccartan's circles
  fn <- function(pos) {
    xy <- matrix(pos, ncol = 2)
    ## distances between all circle centers at current positions
    dm <- as.matrix(dist(xy))
    ## finds overlap amounts
    ## pen squares the overlaps and sums them (heavily penalizes any overlap)
    pen <- sum((pmax(sep_mat - dm, 0))^2) / mean_sep^2
    ## measures how far circles moved from original positions
    disp <- mean(sqrt(rowSums((xy - coords)^2))) / mean_sep

    ## final cost = displacement + 10×penalty (overlap is 10× more important than movement)
    disp + 10 * pen
  }

  # run optimization to minimize overlap
  # adapted from mccartan's circles
  ## scaling hint for optimizer
  ### creates a vector of scaling hints for each coordinate
  #### optim runs the optimization starting from original coordinates
  #### optim returns the best positions it found
  res <- optim(coords, fn, method = "L-BFGS-B", control = list(
    ## run optimization
    ### parscale tells the optimizer the typical scale of changes (helps it take appropriate step sizes)
    maxit = 1e5, reltol = 1e-8, parscale = rep(circ_radius, length(coords))))

  # assign optimized positions to centroids
  # adapted from mccartan's circles
  ## contains the optimized coordinates as a flat vector
  ## reshapes back to xy pairs
  xy_opt <- matrix(res$par, ncol = 2)
  ## stores optimized x and y coordinates in new columns
  centroids$x_opt <- xy_opt[, 1]
  centroids$y_opt <- xy_opt[, 2]

  # load U.S. mainland states shapefile for background map
  # not including AK, HI, PR yet for simplicity
  ## state background map using tigris
  ### tigris uses geometries for US Census data
  states_map <- tigris::states(cb = TRUE, resolution = "20m") %>%
    filter(STUSPS %in% states & !STUSPS %in% c("AK", "HI", "PR")) %>%
    st_transform(crs = proj_crs)

  # plot
  p <- ggplot() +
    # map
    geom_sf(data = states_map, fill = "#d7e8ee", color = "white", size = 0.3) +
    # circles
    geom_circle(data = centroids,
                aes(x0 = x_opt, y0 = y_opt, r = radius),
                fill = "darkblue", color = NA, alpha = 0.9) +
    # make sure plot isn't small
    coord_sf(crs = proj_crs) +
    theme_void() +
    labs(title = title_lbl)

  return(p)
}

# GENERATE PLOTS FOR EACH CONGRESS ---------------------------------------------
plot_110 <- congress_plot_lewis(110, "2008")  # 2008 and 110th congress
plot_112 <- congress_plot_cen(2012, "2012")  # 2012 and 112th congress
plot_114 <- congress_plot_cen(2016, "2016")  # 2016 and 114th congress
plot_116 <- congress_plot_cen(2020, "2020")  # 2020 and 116th congress
plot_118 <- congress_plot_cen(2023, "2024")  # 2024 and 118th congress

# SAVE PLOTS -------------------------------------------------------------------
# save as png
ggsave(plot_110,
       filename = "plot2008.png",
       device = "png",
       height = 6, width = 5, units = "in")

ggsave(plot_112,
       filename = "plot2012.png",
       device = "png",
       height = 6, width = 5, units = "in")

ggsave(plot_114,
       filename = "plot2016.png",
       device = "png",
       height = 6, width = 5, units = "in")

ggsave(plot_116,
       filename = "plot2020.png",
       device = "png",
       height = 6, width = 5, units = "in")

ggsave(plot_118,
       filename = "plot2024.png",
       device = "png",
       height = 6, width = 5, units = "in")

# upload
usethis::use_data(dotmap_cd, overwrite = TRUE)

