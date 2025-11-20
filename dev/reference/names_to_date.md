# Extract the date from the layer names This function extracts the date from the layer names of a raster object.

Extract the date from the layer names This function extracts the date
from the layer names of a raster object.

## Usage

``` r
names_to_date(
  raster_cube,
  origin = "1970-01-01",
  tz = "UTC",
  regex = ".*=(\\d+)"
)
```

## Arguments

- raster_cube:

  A raster object.

- origin:

  A character string with the origin date. The default is "1970-01-01".

- tz:

  A character string with the time zone. The default is "UTC".

- regex:

  A character string with the regular expression to extract the date.

## Value

A POSIXct object.
