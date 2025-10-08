#' @title Congressional District level information
#' @name info
#' @description A 435-row table, per each Congress, with descriptive names for each CD.
#' @keywords internal
#'
#' @format Each object is for a particular congress. The year indicates the start
#'  of that Congress. Each observation is a congressional district, which contains a
#'  unique descriptive name.
#'  \describe{
#'    \item{`cd`}{District code. Each row is a a two-letter abbreviation for the
#'    state followed by a dash, and the district number padded with zeros to the
#'    left to be of length 2. At-large districts like Delaware are given a "-01"
#'    for the district number.}
#'    \item{`cd_description`}{The unique descriptive name for the district code.
#'    info_20** column from 2013 onwards are taken from "cd_info" in the
#'    [`ccesMRPprep`](https://github.com/kuriwaki/ccesMRPprep)
#'    package (See Source for full citation). info_20** from earlier years (2005–2011)
#'    were manually coded in Daily Kos style.}
#'  }
#' @author Zachary Donnini, Shiro Kuriwaki, Daily Kos, Downballot
#' @source
#'   2005-2011 descriptive names: Zachary Donnini.
#'
#'   Daily Kos, "2008, 2012 results for districts used in **2012, 2014**"
#'   \url{https://bit.ly/3N4PDZK}
#'
#'   Daily Kos, "2008, 2012, & 2016 results for districts used in **2018**." \url{https://bit.ly/3bXtAPB}
#'
#'   Daily Kos, "2012, 2016 & 2020 presidential election results for congressional districts in **2020**", \url{https://bit.ly/3DRhPcj}
#'
#'   Daily Kos, 2020 presidential election results by later congressional districts:
#'
#'   * __2022__ congressional districts: \url{https://bit.ly/4gLYnBK}
#'   * __2024__ congressional districts: \url{https://bit.ly/47KTvZw}
#'
#'   Daily Kos, congressional district geography and most populous places:
#'
#'   * 119th Congress: \url{https://bit.ly/geography_119}\cr
#'   * 118th Congress: \url{https://bit.ly/geography_118}
#'
#'   PA 2016 descriptive names: Shiro Kuriwaki and Lara Putnam.
#'
#'   Also see Cha, Kuriwaki, and Snyder, 2024,
#'    "Candidates in American General Elections", \url{https://doi.org/10.7910/DVN/DGDRDT},
#'    Harvard Dataverse, for congressional candidate's (instead of President's) vote totals.
#'
#' @examples
#' head(info_2005)
NULL

#' @name info
NULL

#' @rdname info
"info_2005"
#' @rdname info
"info_2007"
#' @rdname info
"info_2009"
#' @rdname info
"info_2011"
#' @rdname info
"info_2013"
#' @rdname info
"info_2015"
#' @rdname info
"info_2017"
#' @rdname info
"info_2019"
#' @rdname info
"info_2021"
#' @rdname info
"info_2023"
#' @rdname info
"info_2025"

library(tidyverse)
library(googlesheets4)
library(remotes)
library(ccesMRPprep)
library(sf)
library(fourthirtyfive)

# match cd names to 2005-2009 ---
## download 2005-2009 and 2018 cd names
names_raw <- gs4_get("1D6out76Jblwvs9bwhb-XQM3ctyp2UjnGrttsqGlX_tY")
c109 <- read_sheet(names_raw, sheet = "109th-midcycle") |> select(cd, name)
c111 <- read_sheet(names_raw, sheet = "111th") |> select(cd, name)
c115 <- read_sheet(names_raw, sheet = "2018") |> select(cd, dailykos_name)

## 109th redistricting in GA and TX
info_2005 <- shp_dot_2005 |>
  left_join(c111, by = "cd") |>
  # overwrite names for GA and TX w/ c109
  left_join(c109 |> rename(name_109 = name), by = "cd") |>
  # replace c111 with c109 for GA and TX
  mutate(cd_description = if_else(str_starts(cd, "GA") | str_starts(cd, "TX"), name_109, name)) |>
  select(-name_109, -name) |>
  st_drop_geometry() |>
  as_tibble()

info_2007 <- shp_dot_2007 |>
  left_join(c111, by = "cd") |>
  rename(cd_description = name) |>
  st_drop_geometry() |>
  as_tibble()

info_2009 <- shp_dot_2009 |>
  left_join(c111, by = "cd") |>
  rename(cd_description = name) |>
  st_drop_geometry() |>
  as_tibble()

# match cd names to 2011-2019 ---
## download 2024 cd names
## use 2018 names from c115
info_2011 <- shp_dot_2011 |>
  left_join(c111, by = "cd") |>
  rename(cd_description = name) |>
  st_drop_geometry() |>
  as_tibble()

## between the 2012-14 and 2016 data, FL, NC, VA (maybe PA) changed their districts
## 113th Congress (January 2013-2015) vs 114th (January 2015-2017) (same)
info_2013 <- shp_dot_2013 |>
  left_join(cd_info_2016 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

info_2015 <- shp_dot_2015 |>
  left_join(cd_info_2016 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

info_2017 <- shp_dot_2017 |>
  left_join(cd_info_2016 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

## between the 2016 and 2018 data, PA changed their districts-- CD116
info_2019 <- shp_dot_2019 |>
  left_join(cd_info_2018 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

## between the 2018 and 2020 data, NC changed their districts
# match cd names to 2021-2023 ---
info_2021 <- shp_dot_2021 |>
  left_join(cd_info_2020 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

## between the 2022 and 2024 data, 4 districts changed their districts: AL, GA, LA, and NC.
info_2023 <- shp_dot_2023 |>
  left_join(cd_info_2022 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

info_2025 <- shp_dot_2025 |>
  left_join(cd_info_2024 |> select(cd, cd_description = dailykos_name)) |>
  st_drop_geometry() |>
  as_tibble()

# Write ---
usethis::use_data(info_2005, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2007, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2009, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2011, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2013, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2015, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2017, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2019, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2021, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2023, overwrite = TRUE, compress = "xz")
usethis::use_data(info_2025, overwrite = TRUE, compress = "xz")
