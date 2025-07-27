utils::globalVariables(c(":=", "rh"))

#' Create a daily aggregation from an hourly dataset
#'
#' https://confluence.ecmwf.int/display/CKB/ERA5+family+post-processed+daily+statistics+documentation
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
#' @param mode The mode of aggregation. The options are \code{agg_fun}, \code{max_min} or \code{last_value}.
#' @param na.rm a logical value indicating whether NA values should be removed
#'   before the computation proceeds.
#' @details The function will create a daily aggregation from an hourly dataset.
#'   The function for aggregation can be informed in the
#'   \code{aggregation_function} parameter, this parameter takes a function as
#'   argument. The default function is \code{\link[base]{mean}}, so a daily
#'   average is returned. Alternatively, the user can choose the \code{mode}
#'   parameter to inform the function to use choosing between the agg_fun,
#'   max_min, and last_value. The \code{agg_fun} will use the function informed
#'   in the \code{aggregation_function} parameter. The \code{max_min} will
#'   return the maximum and minimum values of the day. The \code{last_value}
#'   will return the last value of the day, which is useful for some variables
#'   like precipitation where the last value of the day is the accumulated
#'   precipitation.
#'
#' @return Files with a daily resolution
#' @export
#'

daily_aggregation <- function(folder_in,
                              folder_out,
                              pattern = ".txt$",
                              from = '2002-01-01 00',
                              to = '2021-05-31 23',
                              take_out_first_record = TRUE,
                              aggregation_function = mean,
                              mode = c("agg_fun", "max_min", "last_value")[1],
                              na.rm = FALSE){

  mode <- match.arg(mode, c("agg_fun", "max_min", "last_value"))

  touch_dir(folder_out)

  hourly_files <- list.files(folder_in,
                             full.names = TRUE,
                             pattern = pattern)


  # date
  my_ymdh <- seq(from = lubridate::ymd_h(from),
                 to = lubridate::ymd_h(to),
                 by = 'hours')

  by_ydm <- lubridate::as_date(my_ymdh)

  # transformation
  pb <- txtProgressBar(min = 0, max = length(hourly_files), style = 3)

  for (i in seq_along(hourly_files)) {

    if (take_out_first_record) {
      temp_tbl <- data.table::fread(hourly_files[i], header = TRUE)[-1, ]
    } else {
      temp_tbl <- data.table::fread(hourly_files[i], header = TRUE)
    }

    # create col_name if not exists
    if (!exists("col_name")) {
      col_name <- data.table::copy(colnames(temp_tbl))
    }


    temp_tbl[, `:=`(date = my_ymdh,
                    day = by_ydm)]

    data.table::setnames(temp_tbl, 1, "value")

    if (mode == "agg_fun") {
      temp_tbl <- temp_tbl[, .(daily_agg = aggregation_function(value,
                                                                na.rm = na.rm)),
                           by = day]

      daily_agg <- temp_tbl[ , "daily_agg"]

    } else if (mode == "max_min") {
      temp_tbl <- temp_tbl[, .(max_min = paste(round(max(value), 3),
                                               round(min(value), 3),
                                               sep = ",")),
                           by = day]

      daily_agg <- temp_tbl[ , list(max_min)]

    } else if (mode == "last_value") {
      temp_tbl[, hours := as.factor(lubridate::hour(date))]

      daily_agg <- temp_tbl[hours == 23, 1] #TODO: last value of the day is 23 or 0?
    }


    data.table::setnames(daily_agg, 1, col_name)

    #saving to file
    data.table::fwrite(daily_agg,
                       file.path(folder_out, glue::glue("{file_name(hourly_files[i])}.txt")),
                       row.names = FALSE,
                       dec = ".",
                       sep = ",",
                       quote = FALSE
    )
    setTxtProgressBar(pb, i)

  }

  close(pb)

}




#' Calculate the Relative Humidity from dewpoint and ambient temperature
#'
#' This function performs the calculation of a relative humidity with dewpoint and
#' ambient temperature as input applying the formula: \eqn{RH =
#' 100*10^(m*[(Td/(Td+Tn)) - (Tambient/(Tambient+Tn)]))}. Where \eqn{m} and
#' \eqn{Tn} are constants \cite{(Vaisala, 2013)}.
#'
#'
#' @param folder_dpt Path of the input 2m dewpoint temperature files as
#'   \code{Td}.
#' @param folder_tas Path of the input Near-Surface Air Temperature files as
#'   \code{Tambient}.
#' @param folder_out Path where to save the transformed files
#' @param file_name_output Character string for the Relative humidity files on
#' output.
#' @param m_value The value for the constant \code{m} \cite{(Vaisala, 2013)}.
#' @param Tn_value The value for \code{Tn} (Triple point temperature 273.16 K),
#'   constant \cite{(Vaisala, 2013)}.
#' @param pattern an optional regular expression. Only file names which match
#'   the regular expression will be returned.
#'
#' @return Files with the same temporal resolution as the input
#' @export
#'
#' @references \href{https://www.vaisala.com/en}{VAISALA} (2013) HUMIDITY
#'   CONVERSION FORMULAS, Calculation formulas for humidity.
#'

rh_calculator <- function(folder_dpt,
                          folder_tas,
                          folder_out,
                          file_name_output = "rh",
                          m_value = 7.591386,
                          Tn_value = 240.7263,
                          pattern = ".txt$"
){

  dpt_files <- list.files(folder_dpt,
                          full.names = TRUE,
                          pattern = pattern)

  tas_files <- list.files(folder_tas,
                          full.names = TRUE,
                          pattern = pattern)

  # transformation
  pb <- txtProgressBar(min = 0, max = length(dpt_files), style = 3)

  for (i in seq_along(dpt_files)) {

    temp_dpt <- data.table::fread(dpt_files[i], header = TRUE)

    temp_tas <- data.table::fread(tas_files[i], header = TRUE)

    # create col_name if not exists
    if (!exists("col_name")) {
      col_name <- data.table::copy(colnames(temp_dpt))
    }


    #vaisala formula 2013 formula
    rh_fun <- function(m, td, Tambient, Tn){
      100*10^(m*((td/(td + Tn)) - (Tambient/(Tambient + Tn))))
    }

    data.table::setnames(temp_dpt, "dpt")
    data.table::setnames(temp_tas, "tas")

    rh_tbl <- data.table::data.table(dpt = temp_dpt$dpt,
                                     tas = temp_tas$tas)

    rh_tbl[, rh := rh_fun(m_value, dpt, tas, Tn_value)]

    rh_tbl <- rh_tbl[, "rh"]

    data.table::setnames(rh_tbl, col_name)

    #saving to file
    data.table::fwrite(rh_tbl,
                       file.path(folder_out, glue::glue('{sub("[^0-9]+", file_name_output, file_name(dpt_files[i]))}.txt')),
                       row.names = FALSE,
                       dec = ".",
                       sep = ",",
                       quote = FALSE
    )
    setTxtProgressBar(pb, i)

  }

  close(pb)

}



#' Calculate the wind speed from Eastward and Northward Near-Surface Wind
#'
#'
#' This function performs the calculation of the wind speed from Eastward and
#' Northward Near-Surface Wind as input applying the formula: \eqn{ws =
#' \sqrt(u^2 + v^2)}.
#'
#'
#' @param folder_uas Path of the input Eastward Near-Surface Wind files
#'   \emph{(as u component)}.
#' @param folder_vas Path of the input Northward Near-Surface Wind files
#'   \emph{(as v component)}.
#' @param folder_out Path where to save the transformed files
#' @param col_name The column name for the tables on the output. Usually, the
#'   first date of the time series.
#' @param file_name_output Character string for the Wind speed files on
#'   output.
#' @param pattern an optional regular expression. Only file names which match
#'   the regular expression will be returned.
#'
#'
#' @return Files with the same temporal resolution as the input.
#' @export
#'

windspeed_calculator <- function(folder_uas,
                                 folder_vas,
                                 folder_out,
                                 col_name = "20020101",
                                 file_name_output = "ws",
                                 pattern = ".txt$"
){

  uas_files <- list.files(folder_uas,
                          full.names = TRUE,
                          pattern = pattern)

  vas_files <- list.files(folder_vas,
                          full.names = TRUE,
                          pattern = pattern)

  file_name <- function(x){
    stringr::str_extract(x, "[a-z_]+[0-9]+")
  }


  # transformation
  pb <- txtProgressBar(min = 0, max = length(uas_files), style = 3)

  for (i in seq_along(uas_files)) {

    temp_uas <- data.table::fread(uas_files[i], header = TRUE)

    temp_vas <- data.table::fread(vas_files[i], header = TRUE)

    # create col_name if not exists
    if (!exists("col_name")) {
      col_name <- data.table::copy(colnames(temp_uas))
    }

    ws_tbl <- data.table::data.table(windspeed_values = sqrt((temp_uas)^2 + (temp_vas)^2))

    data.table::setnames(ws_tbl, col_name)


    #saving to file
    data.table::fwrite(ws_tbl,
                       file.path(folder_out, glue::glue('{sub("[^0-9]+", file_name_output, file_name(uas_files[i]))}.txt')),
                       row.names = FALSE,
                       dec = ".",
                       sep = ",",
                       quote = FALSE
    )
    setTxtProgressBar(pb, i)

  }

  close(pb)

}




