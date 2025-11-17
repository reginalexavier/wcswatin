# Main table creator for SWAT Input from Trend SUrface Interpolation

This function is to create the main table for the input table for SWAT.

## Usage

``` r
var_main_creator(targeted_points_path, var_name = "pcp", col_elev = "Elev")
```

## Arguments

- targeted_points_path:

  Shapefile path

- var_name:

  The variable name

- col_elev:

  The column contain the elevation values

## Value

A table

## Examples

``` r
var_main_creator(targeted_points_path = system.file("extdata/sl_centroides",
  "Centroide_watershed_grau.shp",
  package = "wcswatin"
))
#> # A tibble: 258 × 5
#>       ID NAME    LAT  LONG ELEVATION
#>    <dbl> <chr> <dbl> <dbl>     <dbl>
#>  1     1 pcp1  -15.5 -54.9       556
#>  2     2 pcp2  -15.6 -55.1       587
#>  3     3 pcp3  -15.6 -54.7       622
#>  4     4 pcp4  -15.6 -54.7       511
#>  5     5 pcp5  -15.6 -54.9       472
#>  6     6 pcp6  -15.6 -54.8       631
#>  7     7 pcp7  -15.7 -54.7       424
#>  8     8 pcp8  -15.6 -54.6       532
#>  9     9 pcp9  -15.6 -54.8       530
#> 10    10 pcp10 -15.7 -54.8       432
#> # ℹ 248 more rows
```
