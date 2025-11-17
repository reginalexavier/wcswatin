# Input Raster

Method to load ncdf or tiff file and convert them into a SpatRaster
object.

## Usage

``` r
input_raster(x, ...)

# S4 method for class 'character'
input_raster(x, ...)

# S4 method for class 'SpatRaster'
input_raster(x, ...)

# S4 method for class 'RasterLayer'
input_raster(x, ...)

# S4 method for class 'RasterBrick'
input_raster(x, ...)

# S4 method for class 'RasterStack'
input_raster(x, ...)
```

## Arguments

- x:

  path (character) to the file or a SpatRaster object.

- ...:

  additional arguments to
  `terra::`[`rast`](https://rspatial.github.io/terra/reference/rast.html).

## Value

SpatRaster

## See also

[`terra::rast`](https://rspatial.github.io/terra/reference/rast.html)
