#' @title Load congressional district names
#'
#' @description This function returns one or more of the `cd_name_*` datasets
#'
#' @param year Integer vector of years (e.g., `2011` or `c(2005, 2009, 2011)`).
#' @param congress Integer vector of Congress numbers
#'
#' @return A 435-row tibble with congressional district names for the requested
#'  year, with descriptive names for each CD. See `format`.
#' @format Each object is for a particular congress. The year indicates the start
#'  of that Congress. Each observation is a congressional district, which contains a
#'  unique descriptive name.
#'  \describe{
#'    \item{`cd`}{District code. Each row is a a two-letter abbreviation for the
#'    state followed by a dash, and the district number padded with zeros to the
#'    left to be of length 2. At-large districts like Delaware are given a "-01"
#'    for the district number.}
#'    \item{`cd_description`}{The unique descriptive name for the district code.
#'    `cd_name_*` from 2013 onwards are taken from "cd_info" in the
#'    [`ccesMRPprep`](https://github.com/kuriwaki/ccesMRPprep)
#'    package (See Source for full citation). `cd_name_*` from earlier years (2005–2011)
#'    were manually coded in Daily Kos style.}
#'  }
#'
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
#' # load one dataset
#' load_cd_name(year = 2011)
#' load_cd_name(congress = 109)
#'
#' @export
load_cd_name <- function(year = NULL, congress = NULL) {
  if (!is.null(year)) {
    congress <- year_to_cong(year)
  } else if (!is.null(congress)) {
    year <- cong_to_firstyear(congress)
  }

  # one dataset
  load_one <- function(y) {
    nm <- paste0("cd_name_", y)
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

#' @title Congressional District level information
#' @name cd_name
#' @docType data
#' @keywords datasets
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
#'    `cd_name_*` from 2013 onwards are taken from "cd_info" in the
#'    [`ccesMRPprep`](https://github.com/kuriwaki/ccesMRPprep)
#'    package (See Source for full citation). `cd_name_*` from earlier years (2005–2011)
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
#' @aliases cd_name_2005 cd_name_2007 cd_name_2009 cd_name_2011 cd_name_2013
#' @aliases cd_name_2015 cd_name_2017 cd_name_2019 cd_name_2021 cd_name_2023 cd_name_2025
#'
#' @examples
#' head(cd_name_2005)
NULL
