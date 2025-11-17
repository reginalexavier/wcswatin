# Plot a summary of the data

This function creates a graph of daily values observed from several
points on a monthly basis, using a boxplot. You can choose the amount of
points to be randomly computed in the total point set.

## Usage

``` r
summary_plot(
  var_folder,
  sample = 5,
  percent = FALSE,
  from = "2002-01-01",
  to = "2021-05-31",
  x_lab = "Months of observation",
  y_lab = "Vriable name and unit",
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

- from:

  The first date of the series.

- to:

  The last date of the series.

- x_lab:

  Character. Title for the x, see
  [`labs`](https://ggplot2.tidyverse.org/reference/labs.html).

- y_lab:

  Character. Title for the y, see
  [`labs`](https://ggplot2.tidyverse.org/reference/labs.html).

- pattern:

  an optional regular expression. Only file names which match the
  regular expression will be returned.

## Value

A summary plot
