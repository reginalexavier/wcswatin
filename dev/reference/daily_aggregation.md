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
  drop_first_record = TRUE,
  aggregation_function = mean,
  mode = c("agg_fun", "max_min", "value_at_hour")[1],
  value_hour = 0,
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

- drop_first_record:

  Logical. If TRUE, the first row of each input file is removed before
  the date sequence is assigned. This is useful when the input file
  contains a leading 00:00 record that belongs to the previous day and
  should not be part of the requested `from`/`to` range. After this
  optional removal, the number of rows in each input file must match the
  number of hours between `from` and `to`.

- aggregation_function:

  The function to use on the hourly groups like mean, sum, mode, etc

- mode:

  The mode of aggregation. The options are `agg_fun`, `max_min` or
  `value_at_hour`.

- value_hour:

  Integer hour between 0 and 23 used when `mode = "value_at_hour"`. The
  default is 0, which matches products whose daily accumulated value is
  timestamped at 00:00 at the end of the accumulation period. In this
  case, users should include the following day's 00:00 record in the
  requested period.

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
max_min, and value_at_hour. The `agg_fun` will use the function informed
in the `aggregation_function` parameter. The `max_min` will return the
maximum and minimum values of the day. The `value_at_hour` mode will
return the value timestamped at `value_hour`. For daily accumulated
products timestamped at 00:00, set `mode = "value_at_hour"`, keep
`value_hour = 0`, and define `from`/`to` so that the 00:00 record ending
the accumulation period is included. Use `drop_first_record = TRUE` only
when the file also contains an extra leading row that must be discarded
before assigning this date range.
