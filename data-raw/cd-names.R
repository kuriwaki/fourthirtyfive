library(googlesheets4)
library(tidyverse)
library(remotes)
library(ccesMRPprep)
library(sf)

# download CD names
names_raw <- gs4_get("1D6out76Jblwvs9bwhb-XQM3ctyp2UjnGrttsqGlX_tY")
c111 <- read_sheet(names_raw, sheet = "111th")

shp <- read_rds("~/Projects/hexmap/data-out/110th_hex_2025-02-08.rds") |>
  bind_rows() |>
  mutate(cd = to_cd(state, district), .before = 1)


# merge ----
c111_use <- select(c111, cd, descrip = name)

c2009_shp <- shp |>
  select(-geom_label) |>
  arrange(cd) |>
  tidylog::left_join(c111_use) %>%
  mutate(center = geomander::st_centerish(.)$geometry)

c2009_shp |>
  ggplot() + geom_sf(fill = "white") + theme_void() +
  geom_sf_text(aes(label = district, geometry = center), size = 1)


# write ---
usethis::use_data(c2009_shp, overwrite = TRUE)
