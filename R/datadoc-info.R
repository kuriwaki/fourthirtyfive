#' @title Congressional District level information
#' @name info
#' @description A 435-row table, per each Congress, with descriptive names for each CD.
#'
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
#'
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
