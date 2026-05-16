#' Turns multiple time series files into a single table
#'
#' @param files_path path where the files are.
#' @param files_pattern  pattern for the observation/station points name.
#' @param start_date Inform the start date of the series in the format
#' %Y-%m-%d.
#' @param end_date Inform the end date of the series in the format  %Y-%m-%d.
#' @param interval Inform the interval between two observations. See
#'   the function x
#' @param na_value Value encoded as not available, use \code{NA} to leave it the
#'   way it is.
#' @param neg_to_zero logical. inform whether negative values should be
#' corrected to zero.
#'
#' @return A `dataframe`.
#' @export
#'

files_to_table <- function(
  files_path,
  files_pattern,
  start_date = "1970-12-31",
  end_date = "1980-12-31",
  interval = "day",
  na_value = NA,
  neg_to_zero = FALSE
) {
  validate_input_dir(files_path, "files_path")
  validate_scalar_character(files_pattern, "files_pattern")
  validate_scalar_character(start_date, "start_date")
  validate_scalar_character(end_date, "end_date")
  validate_scalar_character(interval, "interval")
  validate_scalar_logical(neg_to_zero, "neg_to_zero")

  start_date_i <- as.Date(start_date, format = "%Y-%m-%d")
  end_date_i <- as.Date(end_date, format = "%Y-%m-%d")
  if (is.na(start_date_i) || is.na(end_date_i)) {
    stop(
      "The arguments 'start_date' and 'end_date' must use the format ",
      "'YYYY-MM-DD'."
    )
  }
  if (start_date_i > end_date_i) {
    stop(
      "The argument 'start_date' must be earlier than or equal to 'end_date'."
    )
  }

  files_name <- list.files(files_path, full.names = FALSE)
  matching_files <- grep(files_pattern, files_name, value = TRUE)
  validate_files_found(matching_files, files_path, files_pattern, "input files")

  point_list <- lapply(
    file.path(files_path, matching_files),
    function(x) {
      data.table::fread(x, header = TRUE)
    }
  )

  points_tbl <- do.call(cbind, point_list)

  names(points_tbl) <- grep(
    files_pattern,
    tools::file_path_sans_ext(files_name),
    value = TRUE
  )
  # atribuir um valor a NA
  if (!is.na(na_value)) {
    points_tbl <- apply(points_tbl, 2, function(x) {
      ifelse(x == na_value, NA, x)
    })
  } else {
    points_tbl
  }

  # eliminar os inferiores a zero
  if (neg_to_zero) {
    points_tbl <- apply(points_tbl, 2, function(x) {
      ifelse(x < 0, 0, x)
    })
  } else {
    points_tbl
  }

  date <- seq.Date(
    from = start_date_i,
    to = end_date_i,
    by = interval
  )

  if (nrow(points_tbl) != length(date)) {
    stop(
      "The matched files have ", nrow(points_tbl),
      " records, but the date range has ", length(date), " dates."
    )
  }

  cbind.data.frame(date, points_tbl)
}


#' Export tables to `txt` or `csv` files
#'
#' @param table A table `data.frame` containing all the observations
#' @param folder_path Character string of the folder where the file must be
#'   saved.
#' @param first_date Character string of the first date for the time series.
#'   This value is used to renaming the columns on every single file while
#'   saving. The actual name is used as the file names. The suggested format is
#'   \code{\%y\%m\%d}
#' @param file_extension Character. `txt` or `csv`.
#'
#' @return NULL
#'
#' @export
#'

table_to_files <- function(
  table,
  folder_path,
  first_date,
  file_extension = "txt"
) {
  validate_scalar_character(folder_path, "folder_path")
  validate_scalar_character(first_date, "first_date")
  validate_scalar_character(file_extension, "file_extension")

  touch_dir(folder_path)

  table <- input_table(table)
  for (i in seq_len(ncol(table))) {
    col_i <- table[, ..i, drop = FALSE]
    f_name_i <- colnames(col_i)

    colnames(col_i) <- first_date

    data.table::fwrite(
      col_i,
      file = file.path(
        folder_path,
        paste0(f_name_i, ".", file_extension)
      )
    )
  }
}
