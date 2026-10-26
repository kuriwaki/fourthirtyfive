# Written by Codex

test_that("bundled hexmaps have valid districts and gap-free state coverage", {
  polygon_parts <- function(geometry) {
    if (inherits(geometry, "POLYGON")) list(geometry) else geometry
  }
  for (year in seq.int(2005L, 2027L, 2L)) {
    hexmap <- cd_hexmap(year = year)
    expect_identical(nrow(hexmap), 435L, info = year)
    expect_identical(anyDuplicated(hexmap$cd), 0L, info = year)
    expect_true(all(sf::st_is_valid(hexmap)), info = year)
    expect_false(any(sf::st_is_empty(hexmap)), info = year)

    states <- hexmap |>
      dplyr::group_by(state = substr(cd, 1, 2)) |>
      dplyr::summarize(.groups = "drop")
    expect_identical(nrow(states), 50L, info = year)
    holes <- vapply(sf::st_geometry(states), function(geometry) {
      sum(vapply(polygon_parts(geometry), length, integer(1)) - 1L)
    }, integer(1))
    expect_true(all(holes == 0L), info = year)
    # Allow floating-point area noise, but no substantive district overlaps.
    overlap <- sum(as.double(sf::st_area(hexmap))) - sum(as.double(sf::st_area(states)))
    expect_true(abs(overlap) < 1, info = year)
  }
})
