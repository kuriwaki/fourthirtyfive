
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cdhexmap

<!-- badges: start -->

<!-- badges: end -->

The goal of cdhexmap is to …

## Installation

You can install the development version of cdhexmap from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
remotes::install_github("kuriwaki/cdhexmap")
```

## Example

``` r
library(cdhexmap)
#> Loading required package: sf
#> Linking to GEOS 3.11.0, GDAL 3.5.3, PROJ 9.1.0; sf_use_s2() is TRUE
#> Loading required package: ggplot2
```

``` r
c2009_shp
#> Simple feature collection with 435 features and 4 fields
#> Active geometry column: geometry
#> Geometry type: GEOMETRY
#> Dimension:     XY
#> Bounding box:  xmin: -2682394 ymin: -23773.04 xmax: 2541702 ymax: 3908262
#> Projected CRS: NAD83 / Conus Albers
#> First 10 features:
#>       cd state district                                        descrip
#> 1  AK-01    AK        1                                  All of Alaska
#> 2  AL-01    AL        1                               Southern Alabama
#> 3  AL-02    AL        2                              Southeast Alabama
#> 4  AL-03    AL        3                           East-central Alabama
#> 5  AL-04    AL        4                          North-central Alabama
#> 6  AL-05    AL        5                               Northern Alabama
#> 7  AL-06    AL        6              Birmingham and Tuscaloose suburbs
#> 8  AL-07    AL        7 Birmingham, Tuscaloosa, and western Black Belt
#> 9  AR-01    AR        1                          Northeastern Arkansas
#> 10 AR-02    AR        2                            Greater Little Rock
#>                          geometry                    center
#> 1  POLYGON ((-2681792 608199.3... POINT (-2554623 660630.1)
#> 2  POLYGON ((560812.3 712038.7... POINT (576211.9 791297.6)
#> 3  POLYGON ((749626.4 816329.6... POINT (686695.9 885543.9)
#> 4  POLYGON ((639697.2 959713, ... POINT (633454.5 998615.8)
#> 5  POLYGON ((485800.6 1003661,...  POINT (512519.9 1055698)
#> 6  POLYGON ((666169.5 1076799,...  POINT (593926.3 1100898)
#> 7  POLYGON ((577942.1 955522.2... POINT (538527.9 938058.6)
#> 8  POLYGON ((476010.1 839899.4... POINT (560392.8 863243.3)
#> 9  POLYGON ((5703.468 1040718,...  POINT (-15946.5 1114678)
#> 10 POLYGON ((-42911.85 1024085... POINT (-90424.92 1054591)
```

``` r
c2009_shp |> 
  ggplot() + geom_sf(fill = "white") + theme_void() +
  geom_sf_text(aes(label = district, geometry = center), size = 1)
```

<img src="man/figures/README-geomsf-1.png" width="100%" />
