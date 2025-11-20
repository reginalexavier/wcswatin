# Calculate the wind speed from Eastward and Northward Near-Surface Wind

This function performs the calculation of the wind speed from Eastward
and Northward Near-Surface Wind as input applying the formula: \\ws =
\sqrt(u^2 + v^2)\\.

## Usage

``` r
windspeed_calculator(
  folder_uas,
  folder_vas,
  folder_out,
  col_name = "20020101",
  file_name_output = "ws",
  pattern = ".txt$"
)
```

## Arguments

- folder_uas:

  Path of the input Eastward Near-Surface Wind files *(as u component)*.

- folder_vas:

  Path of the input Northward Near-Surface Wind files *(as v
  component)*.

- folder_out:

  Path where to save the transformed files

- col_name:

  The column name for the tables on the output. Usually, the first date
  of the time series.

- file_name_output:

  Character string for the Wind speed files on output.

- pattern:

  an optional regular expression. Only file names which match the
  regular expression will be returned.

## Value

Files with the same temporal resolution as the input.
