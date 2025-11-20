# Turns multiple time series files into a single table

Turns multiple time series files into a single table

## Usage

``` r
files_to_table(
  files_path,
  files_pattern,
  start_date = "1970-12-31",
  end_date = "1980-12-31",
  interval = "day",
  na_value = NA,
  neg_to_zero = FALSE
)
```

## Arguments

- files_path:

  path where the files are.

- files_pattern:

  pattern for the observation/station points name.

- start_date:

  Inform the start date of the series in the format %Y-%m-%d.

- end_date:

  Inform the end date of the series in the format %Y-%m-%d.

- interval:

  Inform the interval between two observations. See the function x

- na_value:

  Value encoded as not available, use `NA` to leave it the way it is.

- neg_to_zero:

  logical. inform whether negative values should be corrected to zero.

## Value

A `dataframe`.
