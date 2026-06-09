# Create a daily aggregation from an hourly datacube

`datacube_aggregation()` aggregates a datacube by a given function. The
function can either apply an aggregation function to each day of the
datacube or select the layer timestamped at a given hour.

## Usage

``` r
datacube_aggregation(
  input_path,
  output_filename = "",
  fun = mean,
  cores = 1,
  mode = c("agg_fun", "value_at_hour")[1],
  value_hour = 0,
  date_shift_days = 0,
  drop_first_layer = FALSE,
  ...
)
```

## Arguments

- input_path:

  Path to the datasetcube

- output_filename:

  Path to the output file

- fun:

  Function to be applied to the datasetcube (default is mean). The
  function must be a function that takes a vector as input and returns a
  single value. The main functions to be used are: Sum, Mean, Min, Max,
  First and Last. For last, use
  [`dplyr::last`](https://dplyr.tidyverse.org/reference/nth.html). To
  use customized function say, for example "min", you could use use the
  format fun = \\x) min(x). See
  [`terra::tapp()`](https://rspatial.github.io/terra/reference/tapp.html)
  for more information.

- cores:

  Number of cores to use for the aggregation. Default is 1. See
  [`terra::tapp()`](https://rspatial.github.io/terra/reference/tapp.html)
  for more information. See
  [`terra::tapp()`](https://rspatial.github.io/terra/reference/tapp.html)
  for more information.

- mode:

  The mode of aggregation. The options are `agg_fun` or `value_at_hour`.
  The `agg_fun` mode applies `fun` to all layers in each day. The
  `value_at_hour` mode returns the layer timestamped at `value_hour`.

- value_hour:

  Integer hour between 0 and 23 used when `mode = "value_at_hour"`. The
  default is 0, which matches products whose daily accumulated value is
  timestamped at 00:00 at the end of the accumulation period.

- date_shift_days:

  Whole number of days added to the output layer dates when
  `mode = "value_at_hour"`. Use `-1` for products whose 00:00 timestamp
  represents the previous day.

- drop_first_layer:

  Logical. If TRUE and `mode = "value_at_hour"`, the first selected
  layer is removed. This is useful when the first selected layer
  represents the day before the requested period.

- ...:

  Additional arguments to pass to
  [`names_to_date()`](https://reginalexavier.github.io/wcswatin/reference/names_to_date.md)

## Value

A raster object with the aggregated data

## See also

[`terra::tapp()`](https://rspatial.github.io/terra/reference/tapp.html),
[`names_to_date()`](https://reginalexavier.github.io/wcswatin/reference/names_to_date.md),
[ERA5 family post-processed daily statistics
documentation](https://confluence.ecmwf.int/display/CKB/ERA5+family+post-processed+daily+statistics+documentation)
\# nolint: line_length_linter
