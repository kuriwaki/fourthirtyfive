#' Dodged CD coordinates
#'
#' sf file per congress. The sf geometry is a coordinate of the centroid of the CD,
#'  slightly dodged so that points in dense places do not overlap.
#'
#'
#' @format Each object is for a particular congress. The year indicates the start
#'  of that Congress. Each observational is a congressional district, represented by
#'  a point.  Hawaii and Alaska are not represented.
#' @author Zoya Ahmer, Shiro Kuriwaki, Cory McCartan
#'
#' @source Coordinates from 2012 onwards taken from US Census, `tigris` package.
#'  Coordinates from early Congresses taken from Jefrey B. Lewis, historical congressional
#'  district shapefiles
#' @examples
#' library(sf)
#' library(ggplot2)
#'
#' # plot points combined with state outline
#' shp_dot_2005 |>
#'   ggplot() +
#'   geom_sf(data = shp_states) +
#'   geom_sf(alpha = 0.5)
#' # can also use geom_circle in ggforce(), but need to set constant radius to keep
#' # circle sizes the same
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


#' State map
#'
#' Shapefile of US states with Albers projection. Useful as an outline to dot maps of CDs.
#'
#' @seealso \link{shp_dot}
"shp_states"
