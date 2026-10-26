# fourthirtyfive 0.1.0

First public version, released 2026-10-25

- Access congressional district boundaries, dot maps, hex maps, and descriptive
  names with `cd_boundaries()`, `cd_dotmap()`, `cd_hexmap()`, and `cd_names()`.
  Older `load_*()` functions remain aliases with the same arguments and
  results. 
- Update data to the districts for the 120th (2027) Congress.
- Repair gaps between hexmap districts before bundling the data, so state
  outlines draw without spurious inner borders.
- Correct FL and NC district names for the 113th and 114th Congresses, and
  NC names for the 117th Congress, using descriptions for the matching maps.
- Retrieve district or statewide Cook PVI with `cd_pvi()` for Congress start
  years 1999–2027.  `pvi_to_numeric()` is a helper funciton.
- Compare up to three Congresses in one interactive `cd_mapbox()` map, with
  optional outlines for one or two cities, layer controls, city zoom, and PNG
  export. Requires the optional `mapgl` package and a Mapbox public token;
  see `mapbox-setup` for configuration and usage limits.
- Use `cd_available()` to display supported products and periods with `cli`
  and return an availability table invisibly. 
- Website created
- Thanks to Christopher T. Kenny for help with the overall package design and
  to Jens Wiederspohn for help with the 2027 data.
