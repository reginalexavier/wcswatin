# Save trend-surface point time series to files

Save the list returned by
[`ts_to_point()`](https://reginalexavier.github.io/wcswatin/dev/reference/ts_to_point.md)
as one file per target point. Each output file has a single column named
with the first date of the time series in `YYYYMMDD` format.

## Usage

``` r
ts_point_to_files(
  points_list,
  output_folder,
  file_prefix = "pcp",
  start_date = NULL
)
```

## Arguments

- points_list:

  A list of tables returned by
  [`ts_to_point()`](https://reginalexavier.github.io/wcswatin/dev/reference/ts_to_point.md).

- output_folder:

  Path where output files will be saved.

- file_prefix:

  Prefix used in output file names. It is separated from the point ID by
  an underscore.

- start_date:

  Optional column name to use in all output files. If `NULL`, the first
  date found in each point table is used.

## Value

NULL. Called for side effects.
