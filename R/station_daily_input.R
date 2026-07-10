#' Transforms the raw value from point perspective to a daily perspective
#'
#' Having the collected observation from a point perspective, this function
#' transform the input to a vertical perspective, like a a daily perspective.
#'
#' @param my_folder character. The path to the raw files.
#' @param var_pattern character. A pattern for the observation/station points
#' name.
#' @param main_pattern character. A pattern for the main file  containing all
#' the points with ID, NAME, LAT, LON and ELEVATION.
#' @param start_date character. Inform the start date of the serie in the format
#'   yyyymmdd.
#' @param end_date character. Inform the end date of the serie in the format
#'   yyyymmdd.
#' @param na_value numeric. Value encoded as not available, use \code{NA} for
#'   NA.
#' @param interval charactere. Inform the inteval betwenn two observations. See
#'   the function x
#' @param prefix character. A prefix for naming the table in the format of
#'   "prefix+date". for more detail.
#' @param neg_to_zero logical. Inform whether negative values should be
#' corrected to zero after applying \code{na_value}.
#'
#' @return A list of table
#' @export
#'
#' @importFrom stats na.omit
#' @importFrom utils setTxtProgressBar txtProgressBar
#' @import dplyr
#'
#' @examples
#' folder <- system.file("extdata/pcp_stations", package = "wcswatin")
#' test01 <- point_to_daily(my_folder = folder)
#'
point_to_daily <- function(
  my_folder,
  var_pattern = "p-",
  main_pattern = "pcp",
  start_date = "20170301", # TODO: transformar o formato
  end_date = "20170331",
  interval = "day",
  na_value = -99,
  neg_to_zero = TRUE,
  prefix = "day_"
) {
  validate_input_dir(my_folder, "my_folder")
  validate_scalar_character(var_pattern, "var_pattern")
  validate_scalar_character(main_pattern, "main_pattern")
  validate_scalar_character(start_date, "start_date")
  validate_scalar_character(end_date, "end_date")
  validate_scalar_character(interval, "interval")
  validate_scalar_logical(neg_to_zero, "neg_to_zero")
  validate_scalar_character(prefix, "prefix")

  start_date_i <- as.Date(start_date, format = "%Y%m%d")
  end_date_i <- as.Date(end_date, format = "%Y%m%d")
  if (is.na(start_date_i) || is.na(end_date_i)) {
    stop(
      "The arguments 'start_date' and 'end_date' must use the format ",
      "'YYYYMMDD'."
    )
  }
  if (start_date_i > end_date_i) {
    stop(
      "The argument 'start_date' must be earlier than or equal to 'end_date'."
    )
  }

  files_name <- list.files(my_folder, full.names = FALSE)
  main_files <- grep(main_pattern, files_name, value = TRUE)
  var_files <- grep(var_pattern, files_name, value = TRUE)

  if (length(main_files) != 1) {
    stop(
      "The argument 'main_pattern' must match exactly one file in 'my_folder'."
    )
  }
  validate_files_found(var_files, my_folder, var_pattern, "variable files")

  pcp <- data.table::fread(
    file.path(my_folder, main_files),
    header = TRUE
  )

  point_list <- lapply(
    file.path(my_folder, var_files),
    function(x) {
      data.table::fread(x, header = TRUE)
    }
  )

  names_sans_ext <- na.omit(stringr::str_extract(
    files_name,
    paste0(var_pattern, ".*[^.txt]")
  ))

  names(point_list) <- names_sans_ext

  # criando uma sequencia de datas igual ao tamanho da série
  datas <- seq.Date(
    from = start_date_i, # FIXME
    # FIXME colocar no padrão igual a primeira função
    to = end_date_i,
    by = interval
  )

  # juntando as precipitaçoes em uma tabela só
  cplt_tbl <- do.call(cbind, point_list)
  colnames(cplt_tbl) <- names_sans_ext
  if (nrow(cplt_tbl) != length(datas)) {
    stop(
      "The variable files have ",
      nrow(cplt_tbl),
      " records, but the date range has ",
      length(datas),
      " dates."
    )
  }
  cplt_tbl <- dplyr::as_tibble(cplt_tbl) %>% dplyr::mutate(ymd = datas)

  # Missing-value codes are applied before clamping negative values.
  if (!is.na(na_value)) {
    cplt_tbl <- dplyr::mutate_if(cplt_tbl, is.numeric, function(x) {
      ifelse(x == na_value, NA_real_, x)
    })
  } else {
    cplt_tbl
  }

  # setar valores inferios a 0 para zero
  if (neg_to_zero) {
    cplt_tbl <- dplyr::mutate_if(cplt_tbl, is.numeric, function(x) {
      ifelse(x < 0, 0.0, x)
    })
  } else {
    cplt_tbl
  }

  # criando uma lista vazia para receber uma tabela por dia
  tbl_list <- vector(mode = "list", length = nrow(cplt_tbl))

  # criando uma tabela por dia e guardando dentro na lista
  pb <- txtProgressBar(min = 0, max = nrow(cplt_tbl), style = 3)
  for (i in seq_len(nrow(cplt_tbl))) {
    tbl_list[[i]] <- pcp %>%
      dplyr::mutate(pcp = c(t(cplt_tbl[i, names_sans_ext])))
    setTxtProgressBar(pb, i)
  }
  close(pb)

  # renomeando as tabelas pela data respectiva
  names(tbl_list) <- paste0(prefix, datas)

  tbl_list
}


#' Save the csv files after transformation to daily form
#'
#' @param tbl_list list. A list, the output of the x function
#' @param path The path where the files must be saved
#'
#' @return No return value (`NULL`), called for side effects. Writes one CSV
#'   file for every named element of `tbl_list` to `path`; output files are
#'   named `<element-name>.csv` and retain the element table structure.
#' @export
#'
#' @examples
#' daily_dir <- tempfile("wcswatin-daily-")
#' dir.create(daily_dir)
#' daily_tables <- list(
#'   day_20200101 = data.frame(ID = 1:2, pcp = c(1.2, 0))
#' )
#' save_daily_tbl(daily_tables, daily_dir)
#' list.files(daily_dir)
#' unlink(daily_dir, recursive = TRUE)
save_daily_tbl <- function(tbl_list, path) {
  for (i in seq_along(tbl_list)) {
    data.table::fwrite(
      tbl_list[[i]], # excluindo a coluna de data
      file = glue::glue("{path}/{names(tbl_list[i])}.csv")
    )
  }
}
