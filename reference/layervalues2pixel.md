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
if (FALSE) { # \dontrun{
# Example (pseudo-code):
# lv <- cube2table(input_path, var = "tmin", n_layers = 10, study_area)
# mt <- main_input_var(study_area, var_name = "tmin")
# out <- layervalues2pixel(lv, mt, col_name = "20220101", inline_output = TRUE)
} # }
```
