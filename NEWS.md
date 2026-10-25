# fourthirtyfive 0.0.4.9000

- Add `cd_boundaries()`, `cd_dotmap()`, `cd_hexmap()`, and `cd_names()` as the
  primary accessors. Existing `load_*()` functions remain available as
  compatibility wrappers, with the same arguments and results.
- Add `cd_available()` to display supported products and periods with `cli`
  and return an availability table invisibly. Use `quiet = TRUE` for just the
  table.
