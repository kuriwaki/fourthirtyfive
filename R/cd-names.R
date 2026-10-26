# Written by Codex
#' @title Descriptive congressional district names
#'
#' @description Retrieve descriptive geographical names for congressional
#'   districts in one or more Congresses.
#'
#' @inheritParams cd_params
#'
#' @details Supply `year` or `congress`. Bundled district names cover Congresses
#'   109-120 (start years 2005-2027).
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
#' @family congressional district functions
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
#'
#' @format Each object is for a particular Congress. The year indicates the start
#'  of that Congress. Each observation is a congressional district, which contains a
#'  unique descriptive name.
#'  \describe{
#'    \item{`cong`}{Congress number, such as 113 for the Congress beginning in 2013.}
#'    \item{`cd`}{District code. Each row is a two-letter abbreviation for the
#'    state followed by a dash, and the district number padded with zeros to the
#'    left to be of length 2. At-large districts like Delaware are given a "-01"
#'    for the district number.}
#'    \item{`cd_description`}{The unique descriptive name for the district code.
#'    Names in `info_2013` through `info_2025` are taken from `cd_info` in the
#'    [`ccesMRPprep`](https://github.com/kuriwaki/ccesMRPprep)
#'    package (see Source for full citation). Names from earlier years (2005–2011)
#'    were manually coded in Daily Kos style. `info_2027` was coded in October 2026
#'    by visual inspection of Wikipedia pages and then checked via GPT using the
#'    tigris v2.3.0 shapefiles.}
#'  }
#' @author Zachary Donnini, Shiro Kuriwaki, Daily Kos, Downballot
#' @source
#'   2005-2011 descriptive names: Zachary Donnini.
#'
#'   Historical FL and NC corrections for the 113th, 114th, and 117th Congresses:
#'   the `2026-10-corrections` tab in
#'   \url{https://docs.google.com/spreadsheets/d/1D6out76Jblwvs9bwhb-XQM3ctyp2UjnGrttsqGlX_tY/edit}.
#'
#'   Daily Kos, "2008, 2012 results for districts used in **2012, 2014**"
#'   \url{https://docs.google.com/spreadsheets/d/1xn6nCNM97oFDZ4M-HQgoUT3X4paOiSDsRMSuxbaOBdg/edit}
#'
#'   Daily Kos, "2008, 2012, & 2016 results for districts used in **2018**."
#'   \url{https://docs.google.com/spreadsheets/d/1zLNAuRqPauss00HDz4XbTH2HqsCzMe0pR8QmD1K8jk8/edit}
#'
#'   Daily Kos, "2012, 2016 & 2020 presidential election results for congressional districts in **2020**",
#'   \url{https://docs.google.com/spreadsheets/d/1XbUXnI9OyfAuhP5P3vWtMuGc5UJlrhXbzZo3AwMuHtk/edit}
#'
#'   Daily Kos, 2020 presidential election results by later congressional districts:
#'
#'   * __2022__ congressional districts: \url{https://docs.google.com/spreadsheets/d/1CKngqOp8fzU22JOlypoxNsxL6KSAH920Whc-rd7ebuM/edit}
#'   * __2024__ congressional districts: \url{https://docs.google.com/spreadsheets/d/1Sg4ZZz5FcX7lz-m2xqmYtndaO2uEMSaL7x99AbQOvv8/edit}
#'
#'   Daily Kos, congressional district geography and most populous places:
#'
#'   * 119th Congress: \url{https://docs.google.com/spreadsheets/d/12YaBonkqHAjkXhzyKlH2-1t-smZ6J5j76RCBSJEwQHo/edit}\cr
#'   * 118th Congress: \url{https://docs.google.com/spreadsheets/d/1weoLFu2U5lmxQNcB8pFItGHj1Lb_M2E9Oi48sI4w1vY/edit}
#'
#'   PA 2016 descriptive names: Shiro Kuriwaki and Lara Putnam.
#'   PA 2027 descriptive names: Zoya Ahmer and Jens Wiederspohn
#'
#'   2027 manual district names:
#'   \url{https://docs.google.com/spreadsheets/d/1uxD-dKP1DBj_JLM1dXt-K2r8bHhU6o8IIIXCSFcEwaM/edit}
#'
#'   Also see Cha, Kuriwaki, and Snyder, 2024,
#'    "Candidates in American General Elections", \doi{10.7910/DVN/DGDRDT},
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
