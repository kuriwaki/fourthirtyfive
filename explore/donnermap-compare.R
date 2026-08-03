hex21 <- fourthirtyfive::load_cd_shp_hex(2021)
hex23 <- fourthirtyfive::load_cd_shp_hex(2023)

library(sf)

hex21 |>
  st_set_crs(4326) |>          # declare coords are actually lon/lat
  st_transform(st_crs(hex23)) |>    # reproject to match 2023's Mercator
  ggplot() + geom_sf()


bb21 <- st_bbox(hex21)
bb23 <- st_bbox(hex23)
geom21 <- st_geometry(hex21)

origin <- c(unname(bb21["xmin"]), unname(bb21["ymin"]))
scale  <- c(
  unname(bb23["xmax"] - bb23["xmin"]) / unname(bb21["xmax"] - bb21["xmin"]),
  unname(bb23["ymax"] - bb23["ymin"]) / unname(bb21["ymax"] - bb21["ymin"])
)
target <- c(unname(bb23["xmin"]), unname(bb23["ymin"]))

geom_rescaled <- (geom21 - origin) * scale + target

st_set_geometry(hex21, geom_rescaled) |>
  st_set_crs(st_crs(hex23)) |>
  ggplot() + geom_sf()


hex21 |>
  # st_set_crs(4326) |> st_transform() |>
  ggplot() +
  geom_sf() +
  geom_sf(data = load_cd_shp_dot(2023))

MATCH <- shp |>
  st_drop_geometry() |>
  count(state = STATEAB)


library(haven)
dat <- read_dta("~/Dropbox/cces_candidates/release/candidates_2006-2024.dta")
dat |>
  filter(year == 2020, office == "H", won == 1, type == "G") |>
  count(state) |>
  left_join(MATCH, by = "state") |>
  filter(n.x != n.y)


shp <- read_sf("explore/hexmapfiles/HexCDv21wm.shp")
ggplot(shp) + geom_sf()
