# Written by Codex

test_that("earlier FL and NC names match the shared 113th and 114th district plan", {
  districts <- c("FL-03", "FL-04", "FL-05", "FL-10", "NC-02", "NC-09", "NC-13")
  expected <- c(
    "Gainesville area and rural north-central Florida",
    "Jacksonville area, Nassau County, and Baker County",
    "Jacksonville–Orlando corridor",
    "Western Orlando area, Lake County, and northern Polk County",
    "Fayetteville, Sandhills, and southwestern Raleigh suburbs",
    "Charlotte and its northern and southern suburbs",
    "Raleigh and areas to its north and east"
  )
  for (year in c(2013, 2015)) {
    names <- cd_names(year = year)
    expect_identical(names$cd_description[match(districts, names$cd)], expected)
    expect_identical(nrow(names), 435L)
    expect_identical(anyDuplicated(names$cd), 0L)
  }
})

test_that("117th Congress NC names reflect the plan used for the 2020 election", {
  names <- cd_names(year = 2021)
  districts <- c("NC-01", "NC-02", "NC-04", "NC-05", "NC-10", "NC-13")
  expect_identical(names$cd_description[match(districts, names$cd)], c(
    "Northeastern North Carolina and Greenville",
    "Raleigh and southern Wake County",
    "Durham, Chapel Hill, and northern Wake County",
    "Northwestern North Carolina and western Piedmont foothills",
    "Hickory and northwestern Piedmont",
    "Burlington and central Piedmont"
  ))
  expect_identical(nrow(names), 435L)
  expect_identical(anyDuplicated(names$cd), 0L)
})

test_that("historical corrections do not replace appropriate 2016 map names", {
  names <- cd_names(year = 2017)
  expect_identical(names$cd_description[names$cd == "FL-05"], "Jacksonville and Tallahassee areas")
  expect_identical(names$cd_description[names$cd == "NC-13"], "Greensboro and rural western Piedmont")
})
