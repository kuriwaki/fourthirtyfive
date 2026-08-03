#' State map
#'
#' Shapefile of US states with Albers projection. Useful as an outline to dot maps of CDs.
#'
#' @source Alaska and Hawaii are modified following UrbanInstitute/urbnmapr
#'
#' @examples
#' library(ggplot2)
#' cd_shp_states |>
#'   ggplot() +
#'   geom_sf() +
#'   geom_sf_text(aes(label = state))
"cd_shp_states"
