# fourthirtyfive 0.1.0

- Access congressional district boundaries, dot maps, hex maps, and descriptive
  names with `cd_boundaries()`, `cd_dotmap()`, `cd_hexmap()`, and `cd_names()`.
- Use `cd_available()` to display supported products and periods with `cli`
  and return an availability table invisibly. Use `quiet = TRUE` for just the
  table.
- Compare up to three Congresses in one interactive `cd_mapbox()` map, with
  optional magenta outlines for one or two selected cities. See `mapbox-setup`
  for access-token configuration and free usage limits.
