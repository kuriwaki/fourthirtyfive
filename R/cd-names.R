# Written by Codex
#' @title Descriptive congressional district names
#'
#' @description Retrieve descriptive geographical names for congressional
#'   districts in one or more Congresses.
#'
#' @param year Integer vector of years (e.g., `2011` or `c(2005, 2009, 2011)`).
#' @param congress Integer vector of Congress numbers
#'
#' @return A tibble with 435 rows per requested Congress and columns `cong`,
#'   `cd`, and `cd_description`. Multiple Congresses are stacked by row.
#'
#' @seealso [info] for column definitions and sources, and
#'   [ccesMRPprep's `cd_info` documentation](https://github.com/kuriwaki/ccesMRPprep/blob/main/R/datadoc_cd-info.R)
#'   for upstream background.
#'
#' @author Zachary Donnini, Shiro Kuriwaki, Daily Kos, Downballot
#'
#' @examples
#' # load one dataset
#' cd_names(year = 2011)
#' cd_names(congress = 109)
#'
#' # stack multiple Congresses
#' cd_names(congress = 109:119)
#'
#' @family congressional district accessors
#' @seealso [cd_available()] for supported years and Congresses.
#' @export
cd_names <- function(year = NULL, congress = NULL) {
  if (!is.null(year)) {
    congress <- year_to_cong(year)
  } else if (!is.null(congress)) {
    year <- cong_to_firstyear(congress)
  }

  # one dataset
  load_one <- function(y) {
    nm <- paste0("info_", y)
    utils::data(list = nm, package = "fourthirtyfive", envir = environment())
    if (!exists(nm, envir = environment(), inherits = FALSE)) {
      stop(sprintf("`%s` not found in package data. Check available years.", nm), call. = FALSE)
    }
    get(nm, envir = environment())
  }

  out_list <- lapply(unique(year), load_one)

  if (length(out_list) == 1L) {
    out_list[[1]]
  } else {
    dplyr::bind_rows(out_list)
  }
}

#' @title Congressional district name datasets
#' @name info
#' @docType data
#' @keywords datasets
#' @description Bundled tables of descriptive geographical names for
#'   congressional districts. Each dataset is a 435-row table for one Congress.
#'   Use [cd_names()] to select and stack tables by year or Congress number.
#' @keywords internal
#'
#' @format Each object is for a particular congress. The year indicates the start
#'  of that Congress. Each observation is a congressional district, which contains a
#'  unique descriptive name.
#'  \describe{
#'    \item{`cong`}{Congress number, such as 113 for the Congress beginning in 2013.}
#'    \item{`cd`}{District code. Each row is a a two-letter abbreviation for the
#'    state followed by a dash, and the district number padded with zeros to the
#'    left to be of length 2. At-large districts like Delaware are given a "-01"
#'    for the district number.}
#'    \item{`cd_description`}{The unique descriptive name for the district code.
#'    info_20** column from 2013 through 2025 are taken from "cd_info" in the
#'    [`ccesMRPprep`](https://github.com/kuriwaki/ccesMRPprep)
#'    package (See Source for full citation). info_20** from earlier years (2005–2011)
#'    were manually coded in Daily Kos style. `info_2027` was coded in October 2026
#'    by visual inspection of Wikipedia pages and then checked via GPT using the
#'    tigris v2.3.0 shapefiles.}
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
#'   PA 2027 descriptive names: Zoya Ahmer and Jens Wiederspohn
#'
#'   2027 manual district names:
#'   \url{https://bit.ly/4sjkdCA}
#'
#'   Also see Cha, Kuriwaki, and Snyder, 2024,
#'    "Candidates in American General Elections", \url{https://doi.org/10.7910/DVN/DGDRDT},
#'    Harvard Dataverse, for congressional candidate's (instead of President's) vote totals.
#'
#' @seealso [cd_names()] to load and stack one or more Congresses.
#'   See [ccesMRPprep's `cd_info` documentation](https://github.com/kuriwaki/ccesMRPprep/blob/main/R/datadoc_cd-info.R)
#'   for upstream sources, district-boundary history, and related presidential
#'   election data. Its dataset years refer to election maps; the `info_*` years
#'   here refer to the start of a Congress.
#'
#' @aliases info_2005 info_2007 info_2009 info_2011 info_2013
#' @aliases info_2015 info_2017 info_2019 info_2021 info_2023 info_2025
#' @aliases info_2027
#'
#' @examples
#' head(info_2005)
NULL
