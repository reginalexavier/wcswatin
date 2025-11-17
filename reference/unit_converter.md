# Unit Converter

This function performs the same calculation on each observation of a
time series, the time resolution is the same on input as on output. This
feature allows you to convert one unit to another. Just inform the
conversion function in the `FUN` parameter. The standard function
performs the conversion from Kelvin temperatures to degrees Celsius.

## Usage

``` r
unit_converter(
  folder_in,
  folder_out,
  pattern = ".txt$",
  FUN = function(x) (x - 273.15)
)
```

## Arguments

- folder_in:

  Path of the input files

- folder_out:

  Path where to save the transformed files

- pattern:

  an optional regular expression. Only file names which match the
  regular expression will be returned.

- FUN:

  The function to use for transforming the unit of the variable on
  input.

## Value

Files with the same temporal resolution as the input
