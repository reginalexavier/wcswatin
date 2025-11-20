# Trend Surface Interpolation into Raster

This function make an interpolation whith the trend surface method where
the user have to inform the polynome degree. The interpolation is made
over the tageded points for all the serie on the input.

## Usage

``` r
ts_to_area(my_folder, bassin_limit_path, poly_degree = 2, resolution = 0.01)
```

## Arguments

- my_folder:

  Folder containing the ts input files.

- bassin_limit_path:

  A shapefile containing the bassin limit where the trend suface
  function have to be predicted.

- poly_degree:

  The degree to be used in the polynomial function for the trend
  surface.

- resolution:

  The resolution for the output raster in degree.

## Value

A rasterbrick

## Examples

``` r
ts_to_area(
  my_folder = system.file("extdata/ts_input", package = "wcswatin"),
  bassin_limit_path = system.file("extdata/sl_bassin/sl_bassin_limit.shp",
    package = "wcswatin"
  ),
  poly_degree = 2,
  resolution = 0.5
)
#>   |                                                                              |                                                                      |   0%  |                                                                              |==============                                                        |  20%  |                                                                              |============================                                          |  40%  |                                                                              |==========================================                            |  60%  |                                                                              |========================================================              |  80%  |                                                                              |======================================================================| 100%
#> class      : RasterBrick 
#> dimensions : 4, 4, 16, 5  (nrow, ncol, ncell, nlayers)
#> resolution : 0.5, 0.5  (x, y)
#> extent     : -55.6531, -53.6531, -17.42436, -15.42436  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs 
#> source     : memory
#> names      : day_2002.01.01, day_2002.01.02, day_2002.01.03, day_2002.01.04, day_2002.01.05 
#> min values :              0,              0,              0,              0,              0 
#> max values :      70.404189,      26.468815,       3.372788,       7.704003,      25.763596 
#> 
```
