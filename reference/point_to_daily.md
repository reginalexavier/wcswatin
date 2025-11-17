# Transforms the raw value from point perspective to a daily perspective

Having the collected observation from a point perspective, this function
transform the input to a vertical perspective, like a a daily
perspective.

## Usage

``` r
point_to_daily(
  my_folder,
  var_pattern = "p-",
  main_pattern = "pcp",
  start_date = "20170301",
  end_date = "20170331",
  interval = "day",
  na_value = -99,
  negatif_number = TRUE,
  prefix = "day_"
)
```

## Arguments

- my_folder:

  character. The path to the raw files.

- var_pattern:

  character. A pattern for the observation/station points name.

- main_pattern:

  character. A pattern for the main file containing all the points with
  ID, NAME, LAT, LONG and ELEVATION.

- start_date:

  character. Inform the start date of the serie in the format yyyymmdd.

- end_date:

  character. Inform the end date of the serie in the format yyyymmdd.

- interval:

  charactere. Inform the inteval betwenn two observations. See the
  function x

- na_value:

  numeric. Value encoded as not available, use `NA` for NA.

- negatif_number:

  logical. Inform if negative values should be kept.

- prefix:

  character. A prefix for naming the table in the format of
  "prefix+date". for more detail.

## Value

A list of table

## Examples

``` r
folder <- system.file("extdata/pcp_stations", package = "wcswatin")
test01 <- point_to_daily(my_folder = folder)
#>   |                                                                              |                                                                      |   0%  |                                                                              |==                                                                    |   3%  |                                                                              |=====                                                                 |   6%  |                                                                              |=======                                                               |  10%  |                                                                              |=========                                                             |  13%  |                                                                              |===========                                                           |  16%  |                                                                              |==============                                                        |  19%  |                                                                              |================                                                      |  23%  |                                                                              |==================                                                    |  26%  |                                                                              |====================                                                  |  29%  |                                                                              |=======================                                               |  32%  |                                                                              |=========================                                             |  35%  |                                                                              |===========================                                           |  39%  |                                                                              |=============================                                         |  42%  |                                                                              |================================                                      |  45%  |                                                                              |==================================                                    |  48%  |                                                                              |====================================                                  |  52%  |                                                                              |======================================                                |  55%  |                                                                              |=========================================                             |  58%  |                                                                              |===========================================                           |  61%  |                                                                              |=============================================                         |  65%  |                                                                              |===============================================                       |  68%  |                                                                              |==================================================                    |  71%  |                                                                              |====================================================                  |  74%  |                                                                              |======================================================                |  77%  |                                                                              |========================================================              |  81%  |                                                                              |===========================================================           |  84%  |                                                                              |=============================================================         |  87%  |                                                                              |===============================================================       |  90%  |                                                                              |=================================================================     |  94%  |                                                                              |====================================================================  |  97%  |                                                                              |======================================================================| 100%
```
