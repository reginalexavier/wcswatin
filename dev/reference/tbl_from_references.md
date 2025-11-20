# Create a table with the values extracted from the reference points

This function prepares the data table with extracting values in the same
geographical locations as the field stations. This helps to validate
data downloaded from online platforms with data collected from field
stations.

## Usage

``` r
tbl_from_references(raster_file, ref_points, prefix_colname = NULL, ...)
```

## Arguments

- raster_file:

  Raster\* object.

- ref_points:

  A table or sf object containing the field station reference points.
  This input can be a character string informing the address of a .txt
  or .csv file, a data.frame or an sf object. The table must have NAME,
  LAT and LON fields/columns.

- prefix_colname:

  If not null, a string character to be used to prefix the original
  column names.

- ...:

  further arguments from
  [`extract`](https://rspatial.github.io/terra/reference/extract.html).
  These arguments concern only extracting the data in the rasters.

## Value

A table.
