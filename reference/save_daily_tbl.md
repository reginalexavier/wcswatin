# Save the csv files after transformation to daily form

Save the csv files after transformation to daily form

## Usage

``` r
save_daily_tbl(tbl_list, path)
```

## Arguments

- tbl_list:

  list. A list, the output of the x function

- path:

  The path where the files must be saved

## Examples

``` r
if (FALSE) { # \dontrun{
temp <- tempdir()
folder <- system.file("extdata/pcp_stations", package = "wcswatin")
test01 <- point_to_daily(my_folder = folder)
save_daily_tbl(
  tbl_list = test01,
  path = temp
)
unlink(temp, recursive = TRUE)
} # }
```
