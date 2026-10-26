# Public Cook PVI sources

Run from the package root:

```r
source("data-raw/cook-pvi/refresh-public-pvi.R") # Rebuild from saved raw files
source("data-raw/07-create-pvi.R")             # Rebuild package data and coverage
```

The package builder writes one stacked object, `pvi`, to `data/pvi.rda`.
`cd_pvi()` filters this table by Congress and geography. Rows for unavailable
years retain their district/state identifiers, with
`pvi = NA` and `status = "unavailable"`; they contain no nonpublic scores.

Raw TSV downloads, `archive-values.csv`, and `coverage.csv` are generated
locally and ignored by Git. On a fresh clone, download and normalize the
public chart datasets before rebuilding package data:

```sh
Rscript data-raw/cook-pvi/refresh-public-pvi.R --download
Rscript data-raw/07-create-pvi.R
```

`sources.csv` records exact public page and dataset URLs, raw columns, dates, and
row counts. `../cook-pvi-releases.csv` maps Congresses to Cook releases and
presidential elections; these audit fields are kept outside the package dataset.
The builder checks every election pair against the latest two presidential
elections, allowing the documented 2003 House exception (2000 alone).
The refresh script removes Datawrapper's `@@` sort suffixes and
normalizes raw at-large identifiers to `-00`; the package builder converts these
to the package's `-01` convention. No subscriber content is accessed.

## Coverage and missing values

The raw files contain 435 districts for each of Cook's 1997, 2022, 2023, 2025,
and current 2026 releases; 51 statewide scores from the public 2022 table; and
35 current statewide scores observed in the 2026 Senate race table. Those current
state scores use Cook's 2025 basis, incorporating the 2020 and 2024 elections.

`access-audit.csv` records the complete logged-out page audit on October 25,
2026. District archives for 1999–2021, including the separate 2012 redistricting
release, displayed **Subscriber Exclusive**. State archives for 1997, 2001, 2005,
2009, 2013, 2017, 2021, and 2025 also required a subscription. The public 2023
historical comparison charts contain aggregate counts, not district scores.
Missing observations remain missing in the package, with `status = "unavailable"`.

These are Cook's retrospectively recalculated 75/25 scores. Original 50/50
historical PDFs are excluded. The 2022 statewide table confirms Arizona R+2
and Alaska R+8; original 2021 PDFs instead report R+3 and R+9.

## Exact releases and documented reuse

Exact public archive values take precedence over documented equivalent releases.
For example, the published 2022 district table gives ID-02 R+14, while the 2023
archive gives R+15. The builder preserves the exact 2023 value. Values reused
under an explicit equivalence rule receive `status = "unchanged"`.
Their source years remain in the raw archive and builder rules; missing scores
are not inferred from neighboring years.
Cook's 1999 update changed only North Carolina and Virginia, allowing the public
1997 scores to supply other states with that reuse label.

## Current race snapshots

Cook's current race tables were read through the public browser on October 25,
2026. Their row-level source URLs are retained in the two `*-races.csv` files.
Terminal requests to these tables return 403, so the refresh script retains
these snapshots. Refresh them manually through the public browser when needed.
Validate 435 unique House districts and the observed Senate states before
rebuilding package data.

The current 2026 House snapshot takes precedence over July's static 2026 table:
it reflects Missouri's restored map, including MO-02 R+4 and MO-05 D+12.
The separate 2025 archive remains the pre-2026 release, including CA-01 R+12.
