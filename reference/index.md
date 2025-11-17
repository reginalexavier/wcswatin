# Package index

## Package Overview

Package documentation

- [`wcswatin-package`](https://reginalexavier.github.io/wcswatin/reference/wcswatin-package.md)
  [`wcswatin`](https://reginalexavier.github.io/wcswatin/reference/wcswatin-package.md)
  : wcswatin: Climate & Weather SWAT Input.

## Data Input & Loading

Functions for loading different data types

- [`input_raster()`](https://reginalexavier.github.io/wcswatin/reference/input_raster.md)
  : Input Raster
- [`input_table()`](https://reginalexavier.github.io/wcswatin/reference/input_table.md)
  : Input Table
- [`input_vector()`](https://reginalexavier.github.io/wcswatin/reference/input_vector.md)
  : Input Vector
- [`var_names()`](https://reginalexavier.github.io/wcswatin/reference/var_names.md)
  : Shows the variables present in a netcdf

## Raster/NetCDF Processing

Functions for processing gridded climate data

- [`study_area_records()`](https://reginalexavier.github.io/wcswatin/reference/study_area_records.md)
  : Study Area Records
- [`layervalues2pixel()`](https://reginalexavier.github.io/wcswatin/reference/layervalues2pixel.md)
  : Series of Pixel Values
- [`cube2table()`](https://reginalexavier.github.io/wcswatin/reference/cube2table.md)
  : Convert a Cube format data into a Table format
- [`datacube_aggregation()`](https://reginalexavier.github.io/wcswatin/reference/datacube_aggregation.md)
  : Create a daily aggregation from an hourly datacube
- [`daily_aggregation()`](https://reginalexavier.github.io/wcswatin/reference/daily_aggregation.md)
  : Create a daily aggregation from an hourly dataset
- [`tbl_from_references()`](https://reginalexavier.github.io/wcswatin/reference/tbl_from_references.md)
  : Create a table with the values extracted from the reference points

## Station Data Processing

Functions for processing weather station data

- [`point_to_daily()`](https://reginalexavier.github.io/wcswatin/reference/point_to_daily.md)
  : Transforms the raw value from point perspective to a daily
  perspective

- [`files_to_table()`](https://reginalexavier.github.io/wcswatin/reference/files_to_table.md)
  : Turns multiple time series files into a single table

- [`table_to_files()`](https://reginalexavier.github.io/wcswatin/reference/table_to_files.md)
  :

  Export tables to `txt` or `csv` files

- [`fill_gap()`](https://reginalexavier.github.io/wcswatin/reference/fill_gap.md)
  : A wrapper function for filling gaps in the rainfall time series

- [`ts_to_point()`](https://reginalexavier.github.io/wcswatin/reference/ts_to_point.md)
  : Trend Surface Interpolation into Targeded Points

- [`ts_to_area()`](https://reginalexavier.github.io/wcswatin/reference/ts_to_area.md)
  : Trend Surface Interpolation into Raster

- [`save_daily_tbl()`](https://reginalexavier.github.io/wcswatin/reference/save_daily_tbl.md)
  : Save the csv files after transformation to daily form

## SWAT-Specific Functions

Functions for SWAT model input preparation

- [`var_main_creator()`](https://reginalexavier.github.io/wcswatin/reference/var_main_creator.md)
  : Main table creator for SWAT Input from Trend SUrface Interpolation
- [`main_input_var()`](https://reginalexavier.github.io/wcswatin/reference/main_input_var.md)
  : Main table constructor by Variable
- [`rh_calculator()`](https://reginalexavier.github.io/wcswatin/reference/rh_calculator.md)
  : Calculate the Relative Humidity from dewpoint and ambient
  temperature
- [`windspeed_calculator()`](https://reginalexavier.github.io/wcswatin/reference/windspeed_calculator.md)
  : Calculate the wind speed from Eastward and Northward Near-Surface
  Wind

## Data Analysis & Utilities

Helper functions for data analysis

- [`count_na()`](https://reginalexavier.github.io/wcswatin/reference/count_na.md)
  :

  Count the amount or percentage of `NA` in a table by column

- [`summary_table()`](https://reginalexavier.github.io/wcswatin/reference/summary_table.md)
  : Table summary of the data

- [`summary_plot()`](https://reginalexavier.github.io/wcswatin/reference/summary_plot.md)
  : Plot a summary of the data

- [`unit_converter()`](https://reginalexavier.github.io/wcswatin/reference/unit_converter.md)
  : Unit Converter
