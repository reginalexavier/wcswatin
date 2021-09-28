

#' Turns multiple time series files into a single table
#'
#' @param files_path path where the files are.
#' @param files_pattern  pattern for the observation/station points name.
#' @param start_date Inform the start date of the series in the format  %Y-%m-%d.
#' @param end_date Inform the end date of the series in the format  %Y-%m-%d.
#' @param interval Inform the interval between two observations. See
#'   the function x
#' @param na_value Value encoded as not available, use \code{NA} to leave it the
#'   way it is.
#' @param neg_to_zero logical. inform whether negative values should be corrected to zero.
#'
#' @return A `dataframe`.
#' @export
#'

files_to_table <- function(files_path,
                           files_pattern,
                           start_date = "1970-12-31",
                           end_date = "1980-12-31",
                           interval = "day",
                           na_value = NA,
                           neg_to_zero = FALSE) {
  files_name <- list.files(files_path, full.names = FALSE)

  point_list <- lapply(glue::glue(
    "{files_path}/{grep(files_pattern,
                                files_name, value = TRUE)}"
  ),
  function(x) {
    data.table::fread(x, header = TRUE)
  })

  points_tbl <- do.call(cbind, point_list)

  names(points_tbl) <- grep(files_pattern,
                            tools::file_path_sans_ext(files_name),
                            value = TRUE)
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

  date <- seq.Date(from = as.Date(start_date, format = "%Y-%m-%d"),
                   to = as.Date(end_date, format = "%Y-%m-%d"),
                   by = interval)

  cbind.data.frame(date, points_tbl)

}



#' Title
#'
#' @param table A table `data.frame` containing all the observations
#' @param folder_path Character string of the folder where the file must be
#'   saved.
#' @param first_date Character string of the first date for the time series.
#'   This value is used to renaming the columns on every single file while
#'   saving. The actual name is used as the file names. The suggested format is
#'   \code{\%y\%m\%d}
#' @param file_extention Character. `txt` or `csv`.
#'
#' @return NULL
#'
#' @export
#'

table_to_files <- function(table,
                           folder_path,
                           first_date,
                           file_extention = "txt") {
  for (i in seq_len(ncol(table))) {
    col_i <- table[ , i, drop = FALSE]
    f_name_i <- colnames(col_i)
    #print(my_col)
    colnames(col_i) <- first_date
    #print(my_col)
    data.table::fwrite(col_i,
                       file = file.path(folder_path,
                                        paste0(f_name_i, ".", file_extention))
    )
  }

}

#' Transforms the raw value from point perspective to a daily perspective
#'
#' Having the collected observation from a point perspective, this function transform the
#' input to a vertical perspective, like a a daily perspective.
#'
#' @param my_folder character. The path to the raw files.
#' @param var_pattern character. A pattern for the observation/station points name.
#' @param main_pattern character. A pattern for the main file  containing all the
#' points with ID, NAME, LAT, LONG and ELEVATION.
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
#' @param negatif_number logical. Inform if negative values should be kept.
#'
#' @return A list of table
#' @export
#'
#' @importFrom stats na.omit
#' @importFrom utils setTxtProgressBar txtProgressBar
#' @import dplyr
#'
#' @examples
#' folder <- system.file("extdata/pcp_stations", package = "cwswatinput")
#' test01 <- point_to_daily(my_folder = folder)
#'
point_to_daily <- function(my_folder,
                           var_pattern = "p-",
                           main_pattern = "pcp",
                           start_date = "20170301", #TODO: transformar o formato
                           end_date = "20170331",
                           interval = "day",
                           na_value = -99,
                           negatif_number = TRUE,
                           prefix = "day_"
                           ){
  files_name <- list.files(my_folder,
                           full.names = FALSE)

  pcp <- data.table::fread(glue::glue("{my_folder}/{grep(main_pattern,
                                                files_name,
                                                value = TRUE)}"), header = TRUE)

  point_list <- lapply(glue::glue("{my_folder}/{grep(var_pattern,
                                                files_name,
                                                value = TRUE)}"), function(x){
                                                  data.table::fread(x, header = TRUE)
                                                })

  names_sans_ext <- na.omit(stringr::str_extract(files_name, paste0(var_pattern, ".*[^.txt]")))

  names(point_list) <- names_sans_ext

  # criando uma sequencia de datas igual ao tamanho da série
  datas <- seq.Date(from = as.Date(start_date, format = "%Y%m%d"), #FIXME
                    to = as.Date(end_date, format = "%Y%m%d"), #FIXME colocar no padrão igual a primeira função
                    by = interval)

  # juntando as precipitaçoes em uma tabela só
  cplt_tbl <- do.call(cbind, point_list)
  colnames(cplt_tbl) <- names_sans_ext
  cplt_tbl <- dplyr::as_tibble(cplt_tbl) %>% dplyr::mutate(ymd = datas)

  # setar valores inferios a -99 para Nan
  if(!is.na(na_value)){
    cplt_tbl <- dplyr::mutate_if(cplt_tbl, is.numeric, function(x) {
      ifelse(x == na_value, NaN, x)
    })
  } else {
    cplt_tbl
  }

  # setar valores inferios a 0 para zero
  if(negatif_number){
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
    tbl_list[[i]] <- pcp %>% dplyr::mutate(pcp = c(t(cplt_tbl[i, names_sans_ext])))
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
#' @export
#'
#' @examples
#' temp <- tempdir()
#' folder <- system.file("extdata/pcp_stations", package = "cwswatinput")
#' test01 <- point_to_daily(my_folder = folder)
#' save_daily_tbl(tbl_list = test01,
#' path = temp)
#' unlink(temp, recursive = TRUE)
save_daily_tbl <- function(tbl_list, path){
  for (i in seq_along(tbl_list)) {
    data.table::fwrite(tbl_list[[i]], # excluindo a coluna de data
                       file = glue::glue("{path}/{names(tbl_list[i])}.csv "))

  }
}



#' Shows the variables present in a netcdf
#'
#' @param path Path where the netcdf file is located
#'
#' @return List of variable names
#' @export
#'
var_names <- function(path){
  names(ncdf4::nc_open(path)$var)
}


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

fill_gap <- function(dataset, corPeriod = "daily"){
  dataset <- as.data.frame(dataset)
  col_names_original <- colnames(dataset)
  tbl_filled <- hyfo::fillGap(dataset = dataset,
                              corPeriod = corPeriod)
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








