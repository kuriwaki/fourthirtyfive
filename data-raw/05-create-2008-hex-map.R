# remotes::install_github("CoryMcCartan/hexmap")
library(hexmap)
library(tidyverse)
library(glue)
library(sf)
library(tigris)
library(geomander)
library(usethis)

options(tigris_use_cache = TRUE)

# download 111th Congress district shapefiles (2008 election) ----
safe_get_lewis <- function(abbr, congress) {
    tryCatch(
        get_lewis(state = abbr, congress = congress),
        error = function(e) {
            urls <- get_lewis(state = abbr, congress = congress, path_only = TRUE)
            read_sf(urls[!is.na(urls)][1])
        }
    )
}

d_2008 <- map_dfr(state.abb, \(abbr) {
    message(abbr)
    safe_get_lewis(abbr, congress = 111) |>
        transmute(state = abbr, cd_2020 = as.integer(district), geometry)
}) |>
    st_make_valid() |>
    st_transform(4269) |>
    arrange(state, cd_2020)

d_usa <- states(cb = TRUE, resolution = "20m", year = 2020) |>
    filter(!STUSPS %in% c("PR", "DC"))

# make state hexmaps using Cory McCartan's hexmap (download from github) ----
state_hex <- map(set_names(state.abb), \(abbr) hexmap:::make_hex_map(abbr, d_2008, d_usa)) |>
    bind_rows()

shifted_labels <- state_hex |>
    st_set_geometry("geom_label") |>
    st_transform(4269) |>
    shift_geometry() |>
    pull(geom_label)

state_hex <- state_hex |>
    st_transform(4269) |>
    shift_geometry() |>
    mutate(geom_label = shifted_labels)

# position states using Daily Kos state grid ----
# hexSTv20.shp available from Daily Kos (copy to data-raw/HexSTv20/)
d_states <- state_hex |>
    group_by(state) |>
    summarize(n = n()) |>
    mutate(ctr = st_centroid(geometry),
           area = st_area(geometry),
           rescale = 435 * as.numeric(area / sum(area)))
hex_scale <- sqrt(median(as.numeric(d_states$area)))
scale_fac <- with(d_states, sqrt(n / rescale))
names(scale_fac) <- d_states$state

dk_states <- read_sf("data-raw/hexmap_2018/HexSTv20/HexSTv20.shp") |>
    select(state = STATEAB) |>
    st_set_crs(3857) |>
    suppressWarnings() |>
    mutate(area = as.numeric(st_area(geometry)))

# rescale states where district count changed between 2008 and HexSTv20 (~2018)
n_2008_override <- c(
    AZ=8,  FL=25, GA=13, NV=3,  SC=6,  TX=32, UT=3,  WA=9,
    IL=19, IA=5,  LA=7,  MA=10, MI=15, MO=9,  NJ=13, NY=29, OH=18, PA=19
)
dk_states <- dk_states |>
    mutate(n_2018 = round(435 * area / sum(area)),
           n_adj  = coalesce(n_2008_override[state], as.double(n_2018)),
           area   = area * n_adj / n_2018) |>
    select(-n_2018, -n_adj)

dk_scale <- sqrt(median(dk_states$area))
m_scale <- diag(2) / dk_scale
dk_ctr <- st_centroid(st_union(dk_states$geometry))
dk_states$area <- dk_states$area * m_scale[1, 1]
dk_states$geometry <- st_centroid((dk_states$geometry - dk_ctr) * m_scale)

adjustments <- list(
    DE = c(-0.02,  0.00), NJ = c( 0.00, -0.25), NY = c( 0.05,  0.10),
    CT = c( 0.20,  0.02), RI = c( 0.20, -0.16), MT = c( 0.00, -0.03),
    PA = c(-0.10,  0.00), OR = c( 0.13, -0.01), WA = c( 0.10,  0.03),
    FL = c( 0.00, -0.07)
)
for (s in c("NJ", "NY", "CT", "MA", "RI", "VT", "NH", "ME")) {
    base <- if (!is.null(adjustments[[s]])) adjustments[[s]] else c(0, 0)
    adjustments[[s]] <- base + c(0.06, -0.14)
}
for (s in names(adjustments)) {
    idx <- which(dk_states$state == s)
    dk_states$geometry[idx] <- dk_states$geometry[idx] + adjustments[[s]]
}

state_hex2 <- state_hex
for (i in seq_len(nrow(d_states))) {
    abbr <- d_states$state[i]
    idx <- which(state_hex2$state == abbr)
    sc <- scale_fac[abbr]
    new_ctr <- dk_states$geometry[dk_states$state == abbr] * (diag(2) * hex_scale * 0.88)
    state_hex2$geometry[idx]   <- (state_hex2$geometry[idx]   - d_states$ctr[i]) * sc + new_ctr
    state_hex2$geom_label[idx] <- (state_hex2$geom_label[idx] - d_states$ctr[i]) * sc + new_ctr
    if (abbr == "AK")
        state_hex2$geometry[idx] <- rmapshaper::ms_simplify(state_hex2$geometry[idx], 0.02)
}

# format and save ----
shp_hex_2009 <- state_hex2 |>
    transmute(
        cong = 111L,
        cd   = glue("{state}-{str_pad(district, width = 2, pad = '0')}"),
        cd   = str_replace(cd, "-(00|AL)$", "-01")
    ) |>
    arrange(cd)

usethis::use_data(shp_hex_2009, overwrite = TRUE)
