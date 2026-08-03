# Migration plan: move election data into `fourthirtyfive`, adopt `cd_` naming

Status: **planning** (no code written yet)
Last updated: 2026-06-06

## Goal

1. Give `fourthirtyfive` a "long" congressional-district table and two-party
   presidential voteshare data.
2. Move the `cd_info_*` election infrastructure out of
   [`ccesMRPprep`](https://github.com/kuriwaki/ccesMRPprep) and into
   `fourthirtyfive` as the single source of truth.
3. Adopt a consistent `cd_` prefix across the whole package (tidyverse
   family-prefix style) for tab-completion grouping and to avoid clashing with
   base `names()`.
4. Keep direct / `::` references to `ccesMRPprep::cd_info_*` working for
   downstream users via backward-compat bindings, while documenting the narrower
   compatibility limits around explicit `data()` calls.

## Design decisions (settled)

- **Split the legacy combined `cd_info_*` by content type**, each keyed by its
  natural year:
  - **Placenames / descriptions** → `cd_name_*` family, keyed by **odd Congress
    years** (`cd_name_2005 … cd_name_2025`). Renames today's `info_*`.
  - **Election / voteshare** → new `cd_elec_*` family, keyed by **even election
    years** (`cd_elec_2008 … cd_elec_2024`).
- **Long versions** of both: `cd_name_long` and `cd_elec_long`.
  `cd_elec_long` is the clean, contemporaneous long table only: rows where
  `lines == elec` — i.e. presidential years 2008, 2012, 2016, 2020, 2024. The
  distinct midterm-drawn maps (`lines = 2018`, `lines = 2022`) and the relabeled
  midterm duplicates (`lines = 2010`, `2014`) are intentionally **excluded** from
  `cd_elec_long`; their figures live in `cd_elec_cumulative`.
- **Cumulative election long data stays distinct** from the clean long table:
  `cd_elec_cumulative` retains the legacy-style cross-map rows needed to rebuild
  `ccesMRPprep::cd_info_long` and the legacy wide `cd_info_*` (covering line-years
  2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022, 2024). It must be built as a
  **superset** of the legacy data (see the reconstruction caveat under
  Verification).
- **Standardized `cd_elec` variable names**: `fourthirtyfive`'s user-facing
  `cd_elec_*` objects use generic, year-agnostic columns (long: `party`,
  `candidate`, `pct`, `presvotes_total`, `presvotes_DR`; wide: `pct_rep`,
  `pct_dem`, `candidate_rep`, `candidate_dem`, `presvotes_total`,
  `presvotes_DR`). **No year-suffixed columns** (`pct_trump16`,
  `presvotes_total_20`, …). The legacy year-suffixed wide layout exists *only*
  inside the `ccesMRPprep` shim, pivoted on demand from `cd_elec_cumulative`.
- **`cd_` prefix applied package-wide**, including the shapefile objects
  (`shp_* → cd_shp_*`). Old `fourthirtyfive` names are renamed, not kept as
  deprecated aliases.
- **Singular `cd_name_*`** (not `cd_names_*`) — avoids shadowing base `names()`.
- **Loaders** renamed/added: `load_cd_name()`, `load_cd_elec()`,
  `load_cd_shp_dot()`, `load_cd_shp_hex()`, `load_cd_shp()`.
  `load_cd_elec(year = <even>)` returns a wide 435-row table with Democratic and
  Republican vote counts / shares for that map-year. Use a separate argument
  (e.g. `format = "long"` or `format = "cumulative"`) for `cd_elec_long` or
  `cd_elec_cumulative`. Loaders can **optionally left-join the other family**
  (names + voteshare in one call).
- **Cleaner build model**: raw election ingestion produces
  `cd_elec_cumulative`; `cd_elec_long` is filtered from it (`lines == elec`);
  wide `cd_elec_<even>` tables are generated views. This is cleaner than making
  the wide legacy-shaped data the first-class source, because the transformation
  boundaries stay explicit.
- **`fourthirtyfive`'s `cd_name_*` placenames take precedence**: the
  `ccesMRPprep` alias re-derives the legacy name columns from `cd_name_*`; it
  does *not* need to byte-match the old `dailykos_name` lineage.
- **`elec_NY` stays in `ccesMRPprep`** (out of scope for the move).
- Year/congress helpers `cong_to_firstyear()` / `year_to_cong()` stay
  unprefixed (generic, not CD-specific).

## Object inventory (old → new)

| Concern | Old | New | Key |
|---|---|---|---|
| Placenames, wide | `info_2005…2025` | `cd_name_2005…2025` | odd (Congress) |
| Placenames, long | — | `cd_name_long` | — |
| Voteshare, wide (pres. maps) | `ccesMRPprep::cd_info_{2008,2012,2016,2020,2024}` | `cd_elec_{2008,2012,2016,2020,2024}` | even (presidential) |
| Voteshare, wide (midterm maps) | `ccesMRPprep::cd_info_{2018,2022}` | *(no fourthirtyfive wide; rebuilt in shim from cumulative)* | — |
| Voteshare, long | — | `cd_elec_long` (only `lines == elec`) | — |
| Voteshare, cumulative long | `ccesMRPprep::cd_info_long` | `cd_elec_cumulative` | — |
| Dot shapes | `shp_dot_2005…2025` | `cd_shp_dot_2005…2025` | odd |
| Hex shapes | `shp_hex_2005…2025` | `cd_shp_hex_2005…2025` | odd |
| State shapes | `shp_states` | `cd_shp_states` | — |
| Loader (names) | `load_cd_info()` | `load_cd_name()` | — |
| Loader (elec) | — | `load_cd_elec()` | — |
| Loader (dot) | `load_shp_dot()` | `load_cd_shp_dot()` | — |
| Loader (hex) | `load_shp_hex()` | `load_cd_shp_hex()` | — |
| Loader (tigris shp) | `load_cd_shps()` | `load_cd_shp()` | — |
| NY 2018 | `ccesMRPprep::elec_NY` | *(stays in ccesMRPprep)* | — |

`fourthirtyfive` does not need to preserve old direct names such as
`fourthirtyfive::info_2007`, `fourthirtyfive::shp_dot_2023`, or
`load_cd_info()`. They can be forgotten after the rename. Backward compatibility
work is only for `ccesMRPprep::cd_info_*` and `ccesMRPprep::cd_info_long`.

### `cd_elec_long` columns (canonical)

| col | meaning |
|---|---|
| `lines` | map/geography year (even) |
| `cd` | district code |
| `elec` | election year of the result (even) |
| `party`, `candidate` | presidential candidate for `elec` |
| `pct` | two-party voteshare of `candidate` |
| `presvotes_total` | total presidential votes in the CD |
| `presvotes_DR` | D+R presidential votes in the CD |

`cd_elec_long` intentionally excludes the legacy `cd_info_long` cross-map rows
where `lines != elec`; those live in `cd_elec_cumulative`.

### `cd_elec_cumulative` columns (legacy-compatible)

Same columns as `cd_elec_long`, but includes all available combinations of
`lines` and `elec`, including `lines = 2010` and `lines = 2014`. This object is
the source for the `ccesMRPprep::cd_info_long` compatibility binding and for
wide tables that include prior presidential results under later district lines.

### `cd_elec_<even>` columns (standardized wide)

`fourthirtyfive` ships standardized wide tables for **presidential map-years
only**: `cd_elec_2008`, `cd_elec_2012`, `cd_elec_2016`, `cd_elec_2020`,
`cd_elec_2024`. Each is a 435-row pivot of `cd_elec_long`, keyed by `year`
(= `lines` = `elec`) and `cd`, with year-agnostic columns:

| col | meaning |
|---|---|
| `year` | map / election year |
| `cd` | district code |
| `candidate_rep`, `candidate_dem` | the two presidential candidates |
| `pct_rep`, `pct_dem` | two-party voteshares (sum to 1) |
| `presvotes_total` | total presidential votes |
| `presvotes_DR` | D + R presidential votes |

The midterm-drawn maps (2018, 2022) get **no** standalone standardized wide
table here; their legacy wide form is produced in the `ccesMRPprep` shim from
`cd_elec_cumulative`.

### `cd_name_*` columns

`cong`, `cd`, `cd_description`, `largest_place`. The first three preserve the
current `info_*` layout; `largest_place` is **required** (carried over from
`ccesMRPprep::cd_info_*`) so the legacy object can be rebuilt. The legacy
`dailykos_name` column is **not** stored separately — `cd_description` is the
canonical name and the `ccesMRPprep` shim derives `dailykos_name` from it.

### `cd_name_long` columns

Long bind of all `cd_name_<odd>` tables: `cong`, `year`, `cd`, `cd_description`,
`largest_place`.

## Map ↔ Congress crosswalk

Used by the `cd_elec_<even>` views and by the `ccesMRPprep` reconstruction.

| `cd_elec_<even>` (map) | `cd_name_<odd>` (Congresses sharing that map) |
|---|---|
| 2008 | 2007, 2009, 2011 |
| 2012 | 2013, 2015 |
| 2016 | 2017 |
| 2018 | 2019 |
| 2020 | 2021 |
| 2022 | 2023 |
| 2024 | 2025 |

`cd_name_2005` (109th) stays placename-only — predates the Daily Kos voteshare
series and carries the GA/TX mid-decade special case.

## Work in `fourthirtyfive`

**Add**
- `data-raw/create_elec-wide.R` — port of
  `ccesMRPprep/data-raw/create_dist-level-data_*.R` (raw Daily Kos / Downballot
  ingestion). **Also migrate its raw inputs** from `ccesMRPprep/data-raw`
  (`KPEcd2008.csv`, the `read_rds()` source files, the Google Sheet URLs +
  `googlesheets4` auth) — the port is not self-contained without them.
- `data-raw/create_elec-long.R` — builds `cd_elec_cumulative` (a superset of the
  legacy data) from the raw ingested election data, filters `cd_elec_long` to
  `lines == elec` (presidential years), then pivots the standardized wide
  `cd_elec_{2008,2012,2016,2020,2024}`.
- `R/to_cd.R` — internal port of `ccesMRPprep::to_cd()`
  (state + district → `"ST-NN"`), used by the ingestion scripts. Keep it
  **unexported** so it does not mask `ccesMRPprep::to_cd()` when both packages
  are loaded (and `ccesMRPprep` will import `fourthirtyfive`).
- `R/load-cd-elec.R` — `load_cd_elec()` defaults to wide output when `year` is
  specified; it uses an explicit argument for long/cumulative output
  (e.g. `format = c("wide", "long", "cumulative")`). Wide output is only defined
  for presidential `year`s; decide whether `load_cd_elec(2010/2014/2018/2022)`
  errors or routes to cumulative. Optional join to `cd_name_*`.
- `R/datadoc-cd-elec.R` — `@docType data` docs for `cd_elec_long` +
  `cd_elec_cumulative` + `cd_elec_<even>` (port `datadoc_cd-info-long.R`).
- `data/cd_elec_long.rda`, `data/cd_elec_cumulative.rda`,
  `data/cd_elec_{2008,2012,2016,2020,2024}.rda` (presidential map-years only),
  `data/cd_name_long.rda`.

**Rename**
- `R/load-cd-info.R` → `R/load-cd-name.R`; `load_cd_info()` → `load_cd_name()`.
- `R/load-shp-dot.R` → `load_shp_dot()` → `load_cd_shp_dot()`.
- `R/load-shp-hex.R` → `load_shp_hex()` → `load_cd_shp_hex()`.
- `R/load-cd-shps.R` → `load_cd_shps()` → `load_cd_shp()`.
- `data/info_*.rda` → `data/cd_name_*.rda` with columns `cong`, `cd`,
  `cd_description`, `largest_place` (the last brought over from
  `ccesMRPprep::cd_info_*`; `dailykos_name` is dropped in favor of
  `cd_description`).
- `data/shp_dot_*.rda` → `cd_shp_dot_*`; `shp_hex_*` → `cd_shp_hex_*`;
  `shp_states` → `cd_shp_states`.

**Modify**
- `data-raw/03-add-info.R` → rename; **stop importing `ccesMRPprep`** (source
  placenames locally) — removes the current build-time circular dependency.
- `NAMESPACE` / roxygen: export the new `cd_*` functions + data; remove old
  `fourthirtyfive` exports/docs after the rename.
- `README.Rmd` (lines ~104, 110, 117): `load_cd_info(2007)` → `load_cd_name(2007)`,
  `info_2007` → `cd_name_2007`, update the naming-convention paragraph, add a
  `cd_elec_*` / `load_cd_elec()` example. Re-knit to `README.md`.
- `DESCRIPTION`: no new hard dependency (`ccesMRPprep` was build-time only).

Add `# Written by Claude Code` only to scripts created from scratch or
substantially rewritten by Claude. Add `# Reviewed by Codex` only when Codex
substantially reviews or rewrites that script. A pure naming change does not
count and does not require either line.

## Work in `ccesMRPprep` (backward-compat shim)

**Add `R/zzz.R`** — reconstruct legacy combined objects from `fourthirtyfive`:

The legacy wide `cd_info_<even>` objects are rebuilt by pivoting
`cd_elec_cumulative` (not the standardized `fourthirtyfive` wide tables, which
are presidential-only and year-agnostic) and joining names:

```r
.make_cd_info <- function(map_year, cong_year) {
  vote <- fourthirtyfive::cd_elec_cumulative |>
    dplyr::filter(.data$lines == map_year) |>
    # pivot to the legacy cd_info_<map_year> wide layout, including any
    # year-suffixed presvotes_*/pct_* columns that map carried
    <pivot_wider(...)>
  nm <- fourthirtyfive::load_cd_name(year = cong_year) |>          # cd_description, largest_place
    dplyr::transmute(cd, dailykos_name = cd_description, largest_place)
  dplyr::left_join(vote, nm, by = "cd", relationship = "one-to-one")
}
.onLoad <- function(libname, pkgname) {
  ns <- topenv(environment())
  delayedAssign("cd_info_2008", .make_cd_info(2008, 2007), assign.env = ns)
  delayedAssign("cd_info_2012", .make_cd_info(2012, 2013), assign.env = ns)
  delayedAssign("cd_info_2016", .make_cd_info(2016, 2017), assign.env = ns)
  delayedAssign("cd_info_2018", .make_cd_info(2018, 2019), assign.env = ns)
  delayedAssign("cd_info_2020", .make_cd_info(2020, 2021), assign.env = ns)
  delayedAssign("cd_info_2022", .make_cd_info(2022, 2023), assign.env = ns)
  delayedAssign("cd_info_2024", .make_cd_info(2024, 2025), assign.env = ns)
  delayedAssign("cd_info_long", fourthirtyfive::cd_elec_cumulative, assign.env = ns)
}
```

(Legacy `dailykos_name` is re-derived from `cd_description`, which takes
precedence — exact byte-match with the old `dailykos_name` is not required.
`ccesMRPprep::cd_info_long` maps to `cd_elec_cumulative`, **not**
`cd_elec_long`, because the clean long table only contains `lines == elec` rows.)

**Modify**
- `DESCRIPTION`: add `fourthirtyfive` to `Imports`; add
  `Remotes: kuriwaki/fourthirtyfive`.
- `NAMESPACE`: `import(fourthirtyfive)` + `export(cd_info_2008 … cd_info_2024, cd_info_long)`.
- `R/datadoc_cd-info*.R`: keep docs, repoint `@source`/`@seealso` at
  `fourthirtyfive`; drop the bare `"cd_info_2018"` data-object roxygen stubs
  only if `data("cd_info_2018", package = "ccesMRPprep")` compatibility is an
  accepted break.

**Delete**
- `data/cd_info_2008.rda … cd_info_2024.rda`, `data/cd_info_long.rda`.
- `data-raw/create_cd-info-long.R`, `data-raw/create_dist-level-data_*.R`.

**Keep**: `elec_NY` and its docs.

## Verification

- Re-export mechanism is **already tested working**: a throwaway provider +
  consumer pair confirmed `pkg::obj` and `library(pkg); obj` both resolve to the
  identical object via `.onLoad` + `delayedAssign` + `export()`, zero data
  copied.
- `ccesMRPprep` `tests/testthat/test-backcompat.R`: for each legacy object,
  assert columns + spot values against a **pre-migration snapshot** (capture it
  before deleting the `.rda`s). Allow `dailykos_name` to differ where
  `fourthirtyfive`'s `cd_name_*` now takes precedence.
- Assert `ccesMRPprep::cd_info_long` matches the legacy cumulative line-year
  coverage, including `lines = 2010` and `lines = 2014`, while
  `fourthirtyfive::cd_elec_long` contains only rows where `lines == elec`.
- **Cumulative completeness caveat**: the legacy `cd_info_long` is *lossy*
  relative to the legacy wide tables — e.g. `cd_info_2018` carries
  `presvotes_total_20` / `presvotes_DR_20` (2020 totals under 2018 lines) but
  `cd_info_long` has no `lines = 2018, elec = 2020` rows, so those totals are
  absent. To rebuild the legacy wide `cd_info_*` byte-for-byte, build
  `cd_elec_cumulative` from the raw ingestion as a **superset** that keeps
  presvotes even where a `pct` is unavailable. If that is not done, accept that
  reconstructed `cd_info_2018`/`cd_info_2022` may drop a few presvotes columns
  (document as a minor break).
- **Known caveat / release decision to document**:
  `data("cd_info_2018", package = "ccesMRPprep")` may warn "data set not found"
  if the old `.rda` files are removed. Direct / `::` reference is unaffected.
  If `ccesMRPprep` `data()` compatibility matters for one transition release,
  keep small deprecated `.rda` files temporarily in `ccesMRPprep`.

## Suggested build order

1. `fourthirtyfive`: rename objects/functions to `cd_*`; confirm package builds
   + checks clean (no new data yet).
2. `fourthirtyfive`: port raw election ingestion → `cd_elec_cumulative`;
   derive `cd_elec_long` (`lines == elec`), `cd_elec_*`, and `cd_name_long`;
   wire `load_cd_elec()`.
3. `fourthirtyfive`: update `README.Rmd`, re-knit, run `R CMD check`.
4. `ccesMRPprep`: add `fourthirtyfive` dep + `zzz.R` shim; delete moved
   data/scripts; add back-compat tests; `R CMD check`.
