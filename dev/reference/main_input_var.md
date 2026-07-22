# Main table constructor by Variable

Construct a main table needed for the input in SWAT

## Usage

``` r
main_input_var(study_area, var_name = "temp")
```

## Arguments

- study_area:

  The object from 'study_area_records'

- var_name:

  The name of the variable to be extracted

## Value

A table

## Examples

``` r
study_area <- data.frame(
  ID = 1:2,
  LAT = c(-15.0, -15.5),
  LON = c(-56.0, -56.5),
  ELEVATION = c(100, 120)
)
main_input_var(study_area, var_name = "tmin")
#>       ID   NAME   LAT   LON ELEVATION
#>    <int> <char> <num> <num>     <num>
#> 1:     1 tmin_1 -15.0 -56.0       100
#> 2:     2 tmin_2 -15.5 -56.5       120
```
