# Series of Pixel Values

Converts layer-wise values from
[`cube2table()`](https://reginalexavier.github.io/wcswatin/reference/cube2table.md)
into SWAT-style input: a time series for each pixel in the study area.

## Usage

``` r
layervalues2pixel(
  layer_values,
  main_tbl,
  col_name = "20220101",
  inline_output = TRUE,
  path_output = NULL,
  append = FALSE
)
```

## Arguments

- layer_values:

  List. Values extracted per raster layer (from
  [`cube2table()`](https://reginalexavier.github.io/wcswatin/reference/cube2table.md)).

- main_tbl:

  A table with pixel metadata (e.g., from
  [`main_input_var()`](https://reginalexavier.github.io/wcswatin/reference/main_input_var.md)),
  used to name each output table.

- col_name:

  Column name for each SWAT input table. Typically the first date in the
  time series (e.g., "20220101").

- inline_output:

  Logical. If TRUE, returns a list of data.tables.

- path_output:

  Directory to write one file per pixel when `inline_output = FALSE`.

- append:

  Logical. If TRUE, append to existing files; otherwise overwrite.

## Value

A list of tables (when `inline_output = TRUE`) or a set of files in
`path_output` (one for each pixel).

## Examples

``` r
layer_values <- data.frame(
  ID = c(1, 2, 1, 2),
  values = c(10, 20, 11, 21),
  layer_name = c("day_1", "day_1", "day_2", "day_2")
)
main_tbl <- data.frame(NAME = c("tmin_1", "tmin_2"))
layervalues2pixel(
  layer_values = layer_values,
  main_tbl = main_tbl,
  col_name = "20200101"
)
#> $tmin_1
#>    20200101
#>       <num>
#> 1:       10
#> 2:       11
#> 
#> $tmin_2
#>    20200101
#>       <num>
#> 1:       20
#> 2:       21
#> 
```
