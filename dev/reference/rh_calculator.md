# Calculate the Relative Humidity from dewpoint and ambient temperature

This function performs the calculation of a relative humidity with
dewpoint and ambient temperature as input applying the formula: \\RH =
100\*10^(m\*\[(Td/(Td+Tn)) - (Tambient/(Tambient+Tn)\]))\\. Where \\m\\
and \\Tn\\ are constants (Vaisala, 2013).

## Usage

``` r
rh_calculator(
  folder_dpt,
  folder_tas,
  folder_out,
  file_name_output = "rh",
  m_value = 7.591386,
  Tn_value = 240.7263,
  pattern = ".txt$"
)
```

## Arguments

- folder_dpt:

  Path of the input 2m dewpoint temperature files as `Td`.

- folder_tas:

  Path of the input Near-Surface Air Temperature files as `Tambient`.

- folder_out:

  Path where to save the transformed files

- file_name_output:

  Character string for the Relative humidity files on output.

- m_value:

  The value for the constant `m` (Vaisala, 2013).

- Tn_value:

  The value for `Tn` (Triple point temperature 273.16 K), constant
  (Vaisala, 2013).

- pattern:

  an optional regular expression. Only file names which match the
  regular expression will be returned.

## Value

Files with the same temporal resolution as the input

## References

[VAISALA](https://www.vaisala.com/en) (2013) HUMIDITY CONVERSION
FORMULAS, Calculation formulas for humidity.
