# Create a daily aggregation from an hourly dataset

https://confluence.ecmwf.int/display/CKB/ERA5+family+post-processed+daily+statistics+documentation
\# nolint: line_length_linter

## Usage

``` r
daily_aggregation(
  folder_in,
  folder_out,
  pattern = ".txt$",
  from = "2002-01-01 00",
  to = "2021-05-31 23",
  take_out_first_record = TRUE,
  aggregation_function = mean,
  mode = c("agg_fun", "max_min", "last_value")[1],
  na.rm = FALSE
)
```

## Arguments

- folder_in:

  Path of the input files

- folder_out:

  Path where to save the transformed files

- pattern:

  an optional [`regular expression`](https://rdrr.io/r/base/regex.html).
  Only file names which match the regular expression will be returned.

- from:

  The first date of the series, including the hour part.

- to:

  The last date of the series, including the hour part.

- take_out_first_record:

  Logical. If TRUE, the first record of the input file will be removed.
  This is useful when the first record is the hour 00:00, that
  corresponds to the previous day. The length in hour between the from
  and to must be the same as the length of the hours in the input files.

- aggregation_function:

  The function to use on the hourly groups like mean, sum, mode, etc

- mode:

  The mode of aggregation. The options are `agg_fun`, `max_min` or
  `last_value`.

- na.rm:

  a logical value indicating whether NA values should be removed before
  the computation proceeds.

## Value

Files with a daily resolution

## Details

This function allows to aggregate hourly observations to daily time
series. The function for aggregation can be informed in the
`aggregation_function` parameter, this parameter takes a function as
argument. The default function is
[`mean`](https://rdrr.io/r/base/mean.html), so a daily average is
returned.

The function will create a daily aggregation from an hourly dataset. The
function for aggregation can be informed in the `aggregation_function`
parameter, this parameter takes a function as argument. The default
function is [`mean`](https://rdrr.io/r/base/mean.html), so a daily
average is returned. Alternatively, the user can choose the `mode`
parameter to inform the function to use choosing between the agg_fun,
max_min, and last_value. The `agg_fun` will use the function informed in
the `aggregation_function` parameter. The `max_min` will return the
maximum and minimum values of the day. The `last_value` will return the
last value of the day, which is useful for some variables like
precipitation where the last value of the day is the accumulated
precipitation.
