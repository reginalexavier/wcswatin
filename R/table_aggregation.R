#' Create a daily aggregation from an hourly dataset
#'
#' https://confluence.ecmwf.int/display/CKB/ERA5+family+post-processed+daily+statistics+documentation # nolint: line_length_linter
#'
#' This function allows to aggregate hourly observations to daily time series.
#' The function for aggregation can be informed in the
#' \code{aggregation_function} parameter, this parameter takes a function as
#' argument. The default function is \code{\link[base]{mean}}, so a daily
#' average is returned.
#'
#' @param folder_in Path of the input files
#' @param folder_out Path where to save the transformed files
#' @param pattern an optional \code{\link[base:regex]{regular expression}}. Only
#'   file names which match the regular expression will be returned.
#' @param from The first date of the series, including the hour part.
#' @param to The last date of the series, including the hour part.
#' @param take_out_first_record Logical. If TRUE, the first record of the input
#'   file will be removed. This is useful when the first record is the hour
#'   00:00, that corresponds to the previous day. The length in hour between the
#'   from and to must be the same as the length of the hours in the input files.
#' @param aggregation_function The function to use on the hourly groups like
#'   mean, sum, mode, etc
#' @param mode The mode of aggregation. The options are \code{agg_fun},
#' \code{max_min} or \code{value_at_hour}.
#' @param value_hour Integer hour between 0 and 23 used when
#'   \code{mode = "value_at_hour"}. The default is 0, which matches products
#'   whose daily accumulated value is timestamped at 00:00 at the end of the
#'   accumulation period. In this case, users should include the following
#'   day's 00:00 record in the requested period.
#' @param na.rm a logical value indicating whether NA values should be removed
#'   before the computation proceeds.
#' @details The function will create a daily aggregation from an hourly dataset.
#'   The function for aggregation can be informed in the
#'   \code{aggregation_function} parameter, this parameter takes a function as
#'   argument. The default function is \code{\link[base]{mean}}, so a daily
#'   average is returned. Alternatively, the user can choose the \code{mode}
#'   parameter to inform the function to use choosing between the agg_fun,
#'   max_min, and value_at_hour. The \code{agg_fun} will use the function
#'   informed in the \code{aggregation_function} parameter. The \code{max_min}
#'   will return the maximum and minimum values of the day. The
#'   \code{value_at_hour} mode will return the value timestamped at
#'   \code{value_hour}.
#'
#' @return Files with a daily resolution
#' @export
#'

daily_aggregation <- function(
  folder_in,
  folder_out,
  pattern = ".txt$",
  from = "2002-01-01 00",
  to = "2021-05-31 23",
  take_out_first_record = TRUE,
  aggregation_function = mean,
  mode = c("agg_fun", "max_min", "value_at_hour")[1],
  value_hour = 0,
  na.rm = FALSE # nolint: object_name_linter
) {
  mode <- match.arg(mode, c("agg_fun", "max_min", "value_at_hour"))

  validate_input_dir(folder_in, "folder_in")
  validate_scalar_character(folder_out, "folder_out")
  validate_scalar_character(pattern, "pattern")
  validate_scalar_logical(take_out_first_record, "take_out_first_record")
  validate_function(aggregation_function, "aggregation_function")
  validate_scalar_logical(na.rm, "na.rm")
  if (
    !is.numeric(value_hour) ||
      length(value_hour) != 1 ||
      is.na(value_hour) ||
      value_hour != as.integer(value_hour) ||
      value_hour < 0 ||
      value_hour > 23
  ) {
    stop("The argument 'value_hour' must be a whole number from 0 to 23.")
  }
  value_hour <- as.integer(value_hour)

  from_date <- suppressWarnings(lubridate::ymd_h(from, quiet = TRUE))
  to_date <- suppressWarnings(lubridate::ymd_h(to, quiet = TRUE))

  if (is.na(from_date) || is.na(to_date)) {
    stop(
      "The arguments 'from' and 'to' must use the format 'YYYY-MM-DD HH'."
    )
  }

  # Check if the range between from and to is a valid interval
  if (from_date > to_date) {
    stop("The argument 'from' must be earlier than or equal to 'to'.")
  }

  touch_dir(folder_out)

  hourly_files <- list.files(folder_in, full.names = TRUE, pattern = pattern)
  validate_files_found(hourly_files, folder_in, pattern, "hourly files")

  # date
  my_ymdh <- seq(
    from = from_date,
    to = to_date,
    by = "hours"
  )

  by_ydm <- lubridate::as_date(my_ymdh)

  # transformation
  pb <- txtProgressBar(min = 0, max = length(hourly_files), style = 3)

  for (i in seq_along(hourly_files)) {
    if (take_out_first_record) {
      temp_tbl <- data.table::fread(hourly_files[i], header = TRUE)[-1, ]
    } else {
      temp_tbl <- data.table::fread(hourly_files[i], header = TRUE)
    }

    if (nrow(temp_tbl) != length(my_ymdh)) {
      stop(
        "The file '", hourly_files[i], "' has ", nrow(temp_tbl),
        " records after preprocessing, but the date range has ",
        length(my_ymdh), " hours."
      )
    }

    # create col_name if not exists
    if (!exists("col_name")) {
      col_name <- data.table::copy(colnames(temp_tbl))
    }

    temp_tbl[, `:=`(
      date = my_ymdh,
      day = by_ydm
    )]

    data.table::setnames(temp_tbl, 1, "value")

    if (mode == "agg_fun") {
      temp_tbl <- temp_tbl[,
        .(daily_agg = aggregation_function(value, na.rm = na.rm)),
        by = day
      ]

      daily_agg <- temp_tbl[, "daily_agg"]
    } else if (mode == "max_min") {
      temp_tbl <- temp_tbl[,
        .(
          max_min = paste(
            round(max(value), 3),
            round(min(value), 3),
            sep = ","
          )
        ),
        by = day
      ]

      daily_agg <- temp_tbl[, list(max_min)]
    } else if (mode == "value_at_hour") {
      temp_tbl[, hours := lubridate::hour(date)]

      daily_agg <- temp_tbl[hours == value_hour, 1]
      if (nrow(daily_agg) == 0) {
        stop(
          "No records were found at value_hour = ", value_hour,
          " in file '", hourly_files[i], "'."
        )
      }
    }

    data.table::setnames(daily_agg, 1, col_name)

    # saving to file
    data.table::fwrite(
      daily_agg,
      file.path(
        folder_out,
        glue::glue("{file_name(hourly_files[i])}.txt")
      ),
      row.names = FALSE,
      dec = ".",
      sep = ",",
      quote = FALSE
    )
    setTxtProgressBar(pb, i)
  }

  close(pb)
}
