#' Unit Converter
#'
#' This function performs the same calculation on each observation of a time
#' series, the time resolution is the same on input as on output. This feature
#' allows you to convert one unit to another. Just inform the conversion
#' function in the \code{FUN} parameter. The standard function performs the
#' conversion from Kelvin temperatures to degrees Celsius.
#'
#' @param folder_in Path of the input files
#' @param folder_out Path where to save the transformed files
#' @param pattern an optional regular expression. Only file names which match
#'   the regular expression will be returned.
#' @param FUN The function to use for transforming the unit of the variable on
#'   input.
#'
#' @return Files with the same temporal resolution as the input
#' @export
#'

unit_converter <- function(
  folder_in,
  folder_out,
  pattern = ".txt$",
  FUN = \(x) (x - 273.15) # nolint: object_name_linter
) {
  touch_dir(folder_out)

  files_list <- list.files(folder_in, full.names = TRUE, pattern = pattern)

  # transformation
  pb <- txtProgressBar(min = 0, max = length(files_list), style = 3)

  for (i in seq_along(files_list)) {
    temp_tbl <- data.table::fread(files_list[i], header = TRUE)

    temp_tbl <- data.table::data.table(FUN(temp_tbl))

    # saving to file
    data.table::fwrite(
      temp_tbl,
      file.path(folder_out, glue::glue("{file_name(files_list[i])}.txt")),
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
#' This function performs the calculation of a relative humidity with dewpoint
#' and ambient temperature as input applying the formula:
#' \eqn{RH = 100*10^(m*[(Td/(Td+Tn)) - (Tambient/(Tambient+Tn)]))}. Where
#' \eqn{m} and \eqn{Tn} are constants \cite{(Vaisala, 2013)}.
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

rh_calculator <- function(
  folder_dpt,
  folder_tas,
  folder_out,
  file_name_output = "rh",
  m_value = 7.591386,
  Tn_value = 240.7263, # nolint: object_name_linter
  pattern = ".txt$"
) {
  dpt_files <- list.files(folder_dpt, full.names = TRUE, pattern = pattern)

  tas_files <- list.files(folder_tas, full.names = TRUE, pattern = pattern)

  # transformation
  pb <- txtProgressBar(min = 0, max = length(dpt_files), style = 3)

  for (i in seq_along(dpt_files)) {
    temp_dpt <- data.table::fread(dpt_files[i], header = TRUE)

    temp_tas <- data.table::fread(tas_files[i], header = TRUE)

    # create col_name if not exists
    if (!exists("col_name")) {
      col_name <- data.table::copy(colnames(temp_dpt))
    }

    # vaisala formula 2013 formula
    # fmt: skip
    rh_fun <- function(m, td, Tambient, Tn) { # nolint: object_name_linter
      100 * 10^(m * ((td / (td + Tn)) - (Tambient / (Tambient + Tn))))
    }

    data.table::setnames(temp_dpt, "dpt")
    data.table::setnames(temp_tas, "tas")

    rh_tbl <- data.table::data.table(
      dpt = temp_dpt$dpt,
      tas = temp_tas$tas
    )

    rh_tbl[, rh := rh_fun(m_value, dpt, tas, Tn_value)]

    rh_tbl <- rh_tbl[, "rh"]

    data.table::setnames(rh_tbl, col_name)

    # saving to file
    data.table::fwrite(
      rh_tbl,
      file.path(
        folder_out,
        glue::glue(
          '{sub("[^0-9]+", file_name_output, file_name(dpt_files[i]))}.txt'
        )
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

windspeed_calculator <- function(
  folder_uas,
  folder_vas,
  folder_out,
  col_name = "20020101",
  file_name_output = "ws",
  pattern = ".txt$"
) {
  uas_files <- list.files(folder_uas, full.names = TRUE, pattern = pattern)

  vas_files <- list.files(folder_vas, full.names = TRUE, pattern = pattern)

  # FIXME: use the name function from utils to avoid duplication
  file_name <- function(x) {
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

    ws_tbl <- data.table::data.table(
      windspeed_values = sqrt((temp_uas)^2 + (temp_vas)^2)
    )

    data.table::setnames(ws_tbl, col_name)

    # saving to file
    data.table::fwrite(
      ws_tbl,
      file.path(
        folder_out,
        glue::glue(
          '{sub("[^0-9]+", file_name_output, file_name(uas_files[i]))}.txt'
        )
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
