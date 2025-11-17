# Create a daily aggregation from an hourly datacube

https://confluence.ecmwf.int/display/CKB/ERA5+family+post-processed+daily+statistics+documentation
\# nolint: line_length_linter

## Usage

``` r
datacube_aggregation(
  input_path,
  output_filename = "",
  fun = sum,
  cores = 1,
  ...
)
```

## Arguments

- input_path:

  Path to the datasetcube

- output_filename:

  Path to the output file

- fun:

  Function to be applied to the datasetcube (default is sum). The
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

- ...:

  Additional arguments to pass to
  [`names_to_date()`](https://reginalexavier.github.io/wcswatin/reference/names_to_date.md)

## Value

A raster object with the aggregated data

## Details

`datacube_aggregation()` aggregates a datacube by a given function. The
function will be applied to each day of the datacube.

## See also

[`terra::tapp()`](https://rspatial.github.io/terra/reference/tapp.html),
[`names_to_date()`](https://reginalexavier.github.io/wcswatin/reference/names_to_date.md)
