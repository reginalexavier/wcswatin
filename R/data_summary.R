#' Table summary of the data
#'
#' This function creates a table summary containing the \code{min}, the
#' \code{max}, the \code{mean}, the \code{sd} \emph{(standard deviation)} and
#' \code{n} \emph{(number of value)} of daily values observed from several
#' points on a monthly basis. When the parameter \code{by_month} is \code{FALSE}
#' the summary return is general, i.e., not on a monthly basis, so the table
#' contains only one row with the same columns \emph{(min, max, mean, sd, and
#' n)}. You can choose the amount of points to be randomly computed in the total
#' point set.
#'
#' @param var_folder Path of the input files
#' @param sample Numeric value, informing the number of files to be used. Until
#'   the total amount is informed, the choice of points to be computed is
#'   random.
#' @param percent When TRUE, the values passed on \code{sample} is use as as a
#'   percentage.
#' @param by_month Either the summary should be done per month or in general.
#'   When true, the parameters \code{from} and \code{to} are ignored.
#' @param from The first date of the series when \code{by_month} is \code{TRUE}.
#'   Remembering that when \code{by_month} is \code{FALSE}, this parameter is
#'   ignored.
#' @param to The last date of the series when \code{by_month} is
#'   \code{TRUE}.Remembering that when \code{by_month} is \code{FALSE}, this
#'   parameter is ignored.
#' @param pattern an optional regular expression. Only file names which match
#'   the regular expression will be returned.
#'
#' @return A summary table.
#'
#' @export
#'

summary_table <- function(
  var_folder,
  sample = 5,
  percent = FALSE,
  by_month = TRUE,
  from = "2002-01-01",
  to = "2021-05-31",
  pattern = ".txt$"
) {
  daily_files <- list.files(var_folder, full.names = TRUE, pattern = pattern)

  total_files <- length(daily_files)

  if (percent) {
    sample_val <- round(total_files * sample / 100)
  } else {
    sample_val <- sample
  }

  message(glue::glue("Ok, {sample_val} files will be processed!\n\n"))

  if (by_month) {
    # date
    my_ymd <- seq(
      from = lubridate::ymd(from),
      to = lubridate::ymd(to),
      by = "day"
    )

    bind_tbl <- do.call(
      rbind,
      lapply(
        sample(
          seq_len(total_files),
          sample_val
        ),
        function(x) {
          temp_file <- daily_files[x]
          temp_tbl <-
            data.table::fread(temp_file, header = TRUE)

          names(temp_tbl) <- "month_values"

          temp_tbl <- dplyr::mutate(
            temp_tbl,
            date = my_ymd,
            month_val = as.factor(lubridate::month(
              date,
              label = TRUE
            ))
          )
        }
      )
    )

    unique_tbl <- bind_tbl %>%
      dplyr::group_nest(Month = month_val) %>%
      dplyr::mutate(
        min = lapply(data, \(x) (min(x$month_values))),
        max = lapply(data, \(x) (max(x$month_values))),
        mean = lapply(data, \(x) (mean(x$month_values))),
        sd = lapply(data, \(x) (sd(x$month_values))),
        n = lapply(data, \(x) (length(x$month_values)))
      ) %>%
      dplyr::select(-data) %>%
      tidyr::unnest(c(min, max, mean, sd, n))

    unique_tbl
  } else {
    temp_tbl <- do.call(
      rbind,
      lapply(
        sample(
          seq_len(total_files),
          sample_val
        ),
        function(x) {
          temp_file <- daily_files[x]
          data.table::fread(temp_file, header = TRUE)
        }
      )
    )

    names(temp_tbl) <- "all_values"

    unique_tbl <- temp_tbl %>%
      summarise(
        min = min(all_values),
        max = max(all_values),
        mean = mean(all_values),
        sd = sd(all_values),
        n = length(all_values)
      )

    unique_tbl
  }
}


#' Plot a summary of the data
#'
#'
#' This function creates a graph of daily values observed from several points on
#' a monthly basis, using a boxplot. You can choose the amount of points to be
#' randomly computed in the total point set.
#'
#' @param var_folder Path of the input files
#' @param sample Numeric value, informing the number of files to be used. Until
#'   the total amount is informed, the choice of points to be computed is
#'   random.
#' @param percent When TRUE, the values passed on \code{sample} is use as as a
#'   percentage.
#' @param from The first date of the series.
#' @param to The last date of the series.
#' @param x_lab Character. Title for the x, see \code{\link[ggplot2]{labs}}.
#' @param y_lab Character. Title for the y, see
#'   \code{\link[ggplot2:labs]{labs}}.
#' @param pattern an optional regular expression. Only file names which match
#'   the regular expression will be returned.
#'
#' @return A summary plot
#' @export
#'

summary_plot <- function(
  var_folder,
  sample = 5,
  percent = FALSE,
  from = "2002-01-01",
  to = "2021-05-31",
  x_lab = "Months of observation",
  y_lab = "Vriable name and unit",
  pattern = ".txt$"
) {
  daily_files <- list.files(var_folder, full.names = TRUE, pattern = pattern)

  total_files <- length(daily_files)

  # date
  my_ymd <- seq(
    from = lubridate::ymd(from),
    to = lubridate::ymd(to),
    by = "day"
  )

  one_file <- function(file) {
    temp_file <- daily_files[file]
    temp_tbl <- dplyr::mutate(
      data.table::fread(temp_file, header = TRUE),
      date = my_ymd,
      month_val = as.factor(lubridate::month(date, label = TRUE)),
      var_file = file_name(temp_file)
    )
    names(temp_tbl)[1] <- "all_values"
    temp_tbl
  }

  if (percent) {
    sample_val <- round(total_files * sample / 100)
  } else {
    sample_val <- sample
  }

  message(glue::glue("Ok, {sample_val} files will be processed!\n\n"))

  # dataset preparation
  data_set <- do.call(
    rbind,
    lapply(
      sample(
        seq_len(total_files),
        sample_val
      ),
      one_file
    )
  )
  # ploting
  ggplot2::ggplot(
    data = data_set,
    ggplot2::aes(month_val, all_values)
  ) +
    ggplot2::geom_boxplot() +
    ggplot2::labs(
      x = x_lab,
      y = y_lab
    )
}
