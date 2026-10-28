# Independent normal vote inputs

The package calculates `normal_vote` from presidential voting data. No published
partisanship-index values enter this calculation. District vote totals come
from [The Downballot](https://the-db.co/presbycd), including its earlier Daily Kos
Elections releases. State estimates use a static snapshot of official Federal
Election Commission vote counts. National baselines are a five-row lookup,
with one Democratic two-party share per presidential election.

The calculation follows the publicly documented 75/25 methodology of the
[Cook Partisan Voting Index (Cook PVI)](https://www.cookpolitical.com/cook-pvi).
We compute values independently from the election inputs described above.

For each geography, let `D_old` and `D_new` be its Democratic shares of the
two-party presidential vote, and `US_old` and `US_new` the corresponding national
shares. The calculation is:

```text
normal_vote = 0.25 * (D_old - US_old) + 0.75 * (D_new - US_new)
```

Each share is `Democratic votes / (Democratic votes + Republican votes)`.
Third-party votes are excluded from both geography and national denominators.
The national totals include all 50 states and DC. The output is a full-precision
signed proportion: positive means more Democratic than the nation, and `0.01`
is one percentage point of Democratic two-party share. No displayed labels or
rounded source percentages enter the calculation.

## Reproduction

Run from the package root:

```sh
# Rebuild package data offline from the tracked normalized inputs.
Rscript data-raw/07-create-normal-vote.R

# Recreate district shares from locally saved raw snapshots, offline.
Rscript data-raw/normal-vote/refresh-normal-vote.R

# Fetch public Downballot sources and refresh the district shares.
Rscript data-raw/normal-vote/refresh-normal-vote.R --download
Rscript data-raw/07-create-normal-vote.R
```

The refresh requires `dplyr`, `glue`, `jsonlite`, `readr`, and `stringr`.
The package-data builder requires `dplyr` and `readr`.

`district-shares.csv` contains only the derived, unrounded two-party shares and
their map and presidential-election keys. Full source spreadsheets are not
redistributed. The Downballot's
[data-use guidance](https://www.the-downballot.com/p/data) requests credit and a
link, and asks users to refrain from reproducing entire spreadsheets. Raw
district vote snapshots are kept under ignored `raw/`.

For downloads, the refresh reads numeric `v` cells from Google Sheets'
Visualization export. It deliberately avoids the formatted `f` cells and
formatted CSV exports, which can round estimated fractional district votes.
Some older district votes are estimates with fractional counts; their precision
is retained. The ignored Downballot CSV snapshots contain only the district ID
and the four candidate counts required for the presidential pair.

`national-baselines.csv` contains exactly one unrounded national Democratic
two-party share for each of 2008, 2012, 2016, 2020, and 2024, with a source URL
and access date. These fixed values were verified from Wikipedia's national
Democratic and Republican candidate vote totals, calculating `D / (D + R)`.
Each row links to the corresponding presidential-election page. The builder
looks up the five constants directly; the refresh does not fetch Wikipedia
or calculate national totals.

`state-votes.csv` is a fixed snapshot of official Democratic and Republican
counts for the 50 states and DC in those five elections. `state-sources.csv`
records its original FEC workbook URLs, source tables, and access dates. The
state estimates use these counts without changing their original coverage or
precision. There is no FEC download or workbook-parsing pipeline; the district
refresh leaves both the state snapshot and national lookup unchanged.

`map-sources.csv` identifies the exact district spreadsheet, tab ID, range,
numeric source columns, expected completeness, and collection date for each
Congress start year. `provenance.csv` records one row for every map and source,
including the static state snapshot and national lookup, and `coverage.csv`
records the resulting package coverage. All dates refer to source access,
not an assertion that the source was first published
on that date. A refresh stops for review if expected source coverage changes.

## Map years, presidential pairs, and gaps

`year` is the Congress start year. `election_year` in the package dataset is the
preceding regular House election. Each map uses the latest two presidential
elections available as of that House election, with 75% weight on the newer one.
District values always use results calculated on that map's own boundaries.

| Congress start | House election map | Presidential pair | Districts calculated | Missing district inputs |
|---|---|---|---:|---|
| 2013 | 2012 | 2008, 2012 | 382 / 435 | 2008 absent for California's 53 districts |
| 2015 | 2014 | 2008, 2012 | 382 / 435 | 2008 absent for California's 53 districts |
| 2017 | 2016 | 2012, 2016 | 408 / 435 | 2012 absent for Florida's 27 districts |
| 2019 | 2018 | 2012, 2016 | 408 / 435 | 2012 absent for Florida's 27 districts |
| 2021 | 2020 | 2016, 2020 | 435 / 435 | None |
| 2023 | 2022 | 2016, 2020 | 0 / 435 | The linked 2022-map source provides 2020 only |
| 2025 | 2024 | 2020, 2024 | 435 / 435 | None |
| 2027 | 2026 | 2020, 2024 | 262 / 435 | 2020 absent for all 173 districts in AL, CA, FL, LA, NC, OH, TN, TX, UT |

All eight map years include calculated values for the 50 states and DC.
Missing district values remain `NA`, with `status = "unavailable"`; other rows
have `status = "calculated"`. Rows for missing inputs retain the date on which
the relevant source was inspected. No old-map vote values are used to fill
missing results on changed maps.

The 2012/2014 source explicitly covers both elections' maps. The 2018-map
workbook includes later 2020 columns; the builder selects 2012 and 2016 so it
does not use future results. The current 2026-map workbook supplies both
presidential years for Missouri's eight districts, using its restored map.
Its 2024 Missouri candidate totals match the 2024-map workbook. The nine
redrawn states remain incomplete even where a particular district may be
unchanged; this pipeline does not infer cross-map equivalence.

The Downballot's source Info tabs identify Jeff Singer, Daniel Donner, and
David Nir as the current source authors and request credit to The Downballot
with a link to `the-db.co/presbycd`. Use that credit when publishing maps based
on these derived district values. The package's measure and its computation
are independent of the source authors.
