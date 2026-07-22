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

## Value

No return value (`NULL`), called for side effects. Writes one CSV file
for every named element of `tbl_list` to `path`; output files are named
`<element-name>.csv` and retain the element table structure.

## Examples

``` r
daily_dir <- tempfile("wcswatin-daily-")
dir.create(daily_dir)
daily_tables <- list(
  day_20200101 = data.frame(ID = 1:2, pcp = c(1.2, 0))
)
save_daily_tbl(daily_tables, daily_dir)
list.files(daily_dir)
#> [1] "day_20200101.csv"
unlink(daily_dir, recursive = TRUE)
```
