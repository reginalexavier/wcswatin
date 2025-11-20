# Table summary of the data

This function creates a table summary containing the `min`, the `max`,
the `mean`, the `sd` *(standard deviation)* and `n` *(number of value)*
of daily values observed from several points on a monthly basis. When
the parameter `by_month` is `FALSE` the summary return is general, i.e.,
not on a monthly basis, so the table contains only one row with the same
columns *(min, max, mean, sd, and n)*. You can choose the amount of
points to be randomly computed in the total point set.

## Usage

``` r
summary_table(
  var_folder,
  sample = 5,
  percent = FALSE,
  by_month = TRUE,
  from = "2002-01-01",
  to = "2021-05-31",
  pattern = ".txt$"
)
```

## Arguments

- var_folder:

  Path of the input files

- sample:

  Numeric value, informing the number of files to be used. Until the
  total amount is informed, the choice of points to be computed is
  random.

- percent:

  When TRUE, the values passed on `sample` is use as as a percentage.

- by_month:

  Either the summary should be done per month or in general. When true,
  the parameters `from` and `to` are ignored.

- from:

  The first date of the series when `by_month` is `TRUE`. Remembering
  that when `by_month` is `FALSE`, this parameter is ignored.

- to:

  The last date of the series when `by_month` is `TRUE`.Remembering that
  when `by_month` is `FALSE`, this parameter is ignored.

- pattern:

  an optional regular expression. Only file names which match the
  regular expression will be returned.

## Value

A summary table.
