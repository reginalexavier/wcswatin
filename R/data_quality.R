#' A wrapper function for filling gaps in the rainfall time series
#'
#' This function is a wrapper for the \code{\link[hyfo]{fillGap}} in the
#' \code{hyfo} \pkg{hyfo} package. The main idea here for this wrapping function
#' is to preserve the column names as they are in the dataset input.
#'
#' @param dataset A dataframe with first column the time, the rest columns are
#'   rainfall data of different gauges.
#' @param corPeriod A string showing the period used in the correlation
#'   computing, e.g. daily, monthly, yearly.
#'
#'
#' @return A dataframe.
#'
#' @export
#'
#' @seealso For more detail about the algorithm used to fill the gaps, please
#'   see \code{\link[hyfo]{fillGap}}.
#'
# fmt: skip
fill_gap <- function(dataset, corPeriod = "daily") { # nolint: object_name_linter
  dataset <- as.data.frame(dataset)
  col_names_original <- colnames(dataset)
  tbl_filled <- hyfo::fillGap(
    dataset = dataset,
    corPeriod = corPeriod
  )
  colnames(tbl_filled) <- col_names_original
  tbl_filled
}


#' Count the amount or percentage of \code{NA} in a table by column
#'
#' @param dataset A dataframe containing rainfall data from different gauges in
#'   its columns.
#' @param percent logical, controls whether to calculate the amount or
#'   percentage of \code{NA}.
#'
#' @return A dataframe.
#'
#' @export

count_na <- function(dataset, percent = FALSE) {
  qt_na <- apply(dataset, 2, function(x) {
    ifelse(!percent, sum(is.na(x)), (sum(is.na(x)) / length(x)) * 100)
  })

  data.frame(column = names(qt_na), Prop_NA = unname(qt_na))
}
