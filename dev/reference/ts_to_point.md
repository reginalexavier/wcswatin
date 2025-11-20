# Trend Surface Interpolation into Targeded Points

This function make an interpolation whith the trend surface method where
the user have to inform the polynome degree. The interpolation is made
over the tageded points for all the serie on the input.

## Usage

``` r
ts_to_point(my_folder, targeted_points_path, poly_degree = 2)
```

## Arguments

- my_folder:

  Folder containing the ts input files.

- targeted_points_path:

  A shapefile containing the targeted points where the trend suface
  function have to predict values.

- poly_degree:

  The degree to be used in the polynomial function for the trend
  surface.

## Value

A list of tibles by day
