# Extract gridded values at station or reference points

Extract values from a raster layer, stack or brick at reference point
locations and return a wide table with one column per point. This
prepares gridded or simulated data for point-based validation against
station observations.

## Usage

``` r
tbl_from_references(raster_file, ref_points, prefix_colname = NULL, ...)
```

## Arguments

- raster_file:

  Raster object accepted by
  [`input_raster`](https://reginalexavier.github.io/wcswatin/dev/reference/input_raster.md).

- ref_points:

  Reference point locations. This input can be a data.frame-like table
  with NAME, LAT and LON columns, a .txt or .csv file path, an sf
  object, a SpatVector object or a vector file path accepted by
  [`input_vector`](https://reginalexavier.github.io/wcswatin/dev/reference/input_vector.md).

- prefix_colname:

  If not null, a character string used to prefix the station column
  names.

- ...:

  further arguments passed to
  [`extract`](https://rspatial.github.io/terra/reference/extract.html).
  These arguments concern only extracting the data in the rasters.

## Value

A data.frame with one row per raster layer and one column per reference
point.

## Details

This function does not calculate validation metrics. Instead, it
prepares the extracted raster values in a table shape that can be
combined with observed station data and then passed to validation tools
such as `hydroGOF::gof()`, `hydroGOF::ggof()` or any other function that
compares observed and simulated series.

The returned table has one row per raster layer and one column per
reference point. Column names are taken from the NAME field in
`ref_points`, optionally prefixed with `prefix_colname`. When combining
this output with observed data, make sure raster layers and observation
rows represent the same dates or time steps in the same order.

Additional arguments passed through `...` are forwarded to
[`extract`](https://rspatial.github.io/terra/reference/extract.html),
allowing options such as `method`, `buffer` and `fun`.

## Examples

``` r
raster_layer <- terra::rast(
  nrows = 2,
  ncols = 2,
  vals = 1:4,
  crs = "EPSG:4326",
  extent = c(-1, 1, -1, 1)
)
raster_stack <- c(raster_layer, raster_layer + 10)

stations <- data.frame(
  NAME = c("station_a", "station_b"),
  LAT = c(-0.5, 0.5),
  LON = c(-0.5, 0.5)
)

simulated <- tbl_from_references(
  raster_file = raster_stack,
  ref_points = stations,
  prefix_colname = "sim"
)

simulated
#>   sim_station_a sim_station_b
#> 1             3             2
#> 2            13            12
```
