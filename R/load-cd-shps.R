# to download CD shps for 109-118 congresses
# temporary download full shapefiles

load_cd_shps <- function(cong = 109:118) {
  # for lewis sf for congresses 109-112
  if (!all(file.exists(glue("~/Downloads/tmp_shp_{109:118}.rds")))) {
    for (c in cong[cong <= 112]) {
      map_df(state.abb, \(x) geomander::get_lewis(state = x, congress = c), .progress = TRUE) |>
        write_rds(glue("~/Downloads/tmp_shp_{c}.rds"))
    }

    # for congress sf for congresses 113-118
    for (c in cong[cong >= 113]) {
      yr = 2*c + 1786 + 1
      tigris::congressional_districts(year = yr, cb = TRUE, resolution = "20m") |>
        write_rds(glue("~/Downloads/tmp_shp_{c}.rds"))
    }
  }
}
