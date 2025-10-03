#' Dotmap: Dodged CD centroids
#'
#' Shapefile of coordinates. Each row contains a coordinate of the centroid of the CD,
#'  slightly dodged so that points in dense places do not overlap.
#'
#' @format Each object is for a particular congress. The year indicates the start
#'  of that Congress. Each observational is a congressional district, represented by
#'  a point.
#' @author Zoya Ahmer, Shiro Kuriwaki, Cory McCartan
#'
#' @source Coordinates from 2012 onwards taken from US Census, `tigris` package.
#'  Coordinates from early Congresses taken from Jeffrey B. Lewis, historical congressional
#'  district shapefiles
#'
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
#' library(ggplot2)
#' shp_states |>
#'   ggplot() +
#'   geom_sf() +
#'   geom_sf_text(aes(label = state))
"shp_states"
