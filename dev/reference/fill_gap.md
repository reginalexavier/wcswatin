# A wrapper function for filling gaps in the rainfall time series

This function is a wrapper for the
[`fillGap`](https://rdrr.io/pkg/hyfo/man/fillGap.html) in the `hyfo`
hyfo package. The main idea here for this wrapping function is to
preserve the column names as they are in the dataset input.

## Usage

``` r
fill_gap(dataset, corPeriod = "daily")
```

## Arguments

- dataset:

  A dataframe with first column the time, the rest columns are rainfall
  data of different gauges.

- corPeriod:

  A string showing the period used in the correlation computing, e.g.
  daily, monthly, yearly.

## Value

A dataframe.

## See also

For more detail about the algorithm used to fill the gaps, please see
[`fillGap`](https://rdrr.io/pkg/hyfo/man/fillGap.html).
