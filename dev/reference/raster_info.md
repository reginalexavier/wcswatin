# Summarize raster file metadata

Summarize raster file metadata

## Usage

``` r
raster_info(path)
```

## Arguments

- path:

  Path to one or more raster files.

## Value

A data.table with one row per raster variable and the columns: file,
variable, long_name, unit, n_layers, n_rows, n_cols, x_min, x_max,
y_min, y_max, crs, has_time, time_start, time_end, time_step and
time_resolution. The file and CRS columns are short labels intended for
console inspection.
