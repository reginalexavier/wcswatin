utils::globalVariables(c("day", "hours", "temperature", "max_min",
                         "m", "dpt", "Tn", "tas", "month_val", "all_values",
                         "values", ".", "data", "sd"))

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




#' Create a table with the values extracted from the reference points
#'
#' This function prepares the data table with extracting values in the same
#' geographical locations as the field stations. This helps to validate data
#' downloaded from online platforms with data collected from field stations.
#'
#' @param raster_file Raster* object.
#' @param ref_points A table or sf object containing the field station reference
#'   points. This input can be a character string informing the address of a
#'   .txt or .csv file, a data.frame or an sf object. The table must have NAME,
#'   LAT and LON fields/columns.
#' @param prefix_colname If not null, a string character to be used to prefix
#'   the original column names.
#' @param ... further arguments from \code{\link[raster]{extract}}. These
#'   arguments concern only extracting the data in the rasters.
#'
#' @return A table.
#' @export
#'
tbl_from_references <- function(raster_file,
                                ref_points,
                                prefix_colname = NULL,
                                ...) {

  if ("sf"  %in% class(ref_points)) {
    ref_points <- ref_points
  } else if  ("data.frame" %in% class(ref_points)) {
    ref_points <- sf::st_as_sf(ref_points,
                               coords = c("LONG", "LAT"),
                               crs = "+proj=longlat +datum=WGS84 +no_defs")
  } else if ("character" %in% class(ref_points) &
             any(stringr::str_ends(ref_points, c(".txt", ".csv")))) {
    tbl_ref <- data.table::fread(ref_points)
    ref_points <- sf::st_as_sf(tbl_ref,
                               coords = c("LONG", "LAT"), #TODO: rename LONG to LON
                               crs = "+proj=longlat +datum=WGS84 +no_defs")
  } else {
    stop("The ref_points must be an object of class `sf`, `data.frame` or a string character of the path of a file with extention `.csv` or `.txt`!")
  }
  # extração dos  valores nos rasters
  values_extracted <- raster::extract(raster_file,
                                      ref_points,
                                      ...)

  df_extracted <- as.data.frame(t(values_extracted),
                                row.names = F)

  if (is.null(prefix_colname)) {

    colnames(df_extracted) <- ref_points$NAME
  } else {
    colnames(df_extracted) <- glue::glue("{prefix_colname}_{ref_points$NAME}")
  }

  df_extracted
}







#' Create a daily aggregation from an hourly dataset
#'
#' This function allows to make the aggregation of hourly observations to daily
#' ones of a time series. The function for aggregation can be informed in the
#' \code{aggregation_function} parameter, this parameter takes a function as
#' argument. The default function is \code{\link[base]{mean}}, so a daily
#' average is returned.
#'
#' @param folder_in Path of the input files
#' @param folder_out Path where to save the transformed files
#' @param pattern an optional \code{\link[base:regex]{regular expression}}. Only
#'   file names which match the regular expression will be returned.
#' @param col_name The column name for the tables on the output. Usually, the
#'   first date of the time series.
#' @param from The first date of the series, including the hour part.
#' @param to The last date of the series, including the hour part.
#' @param aggregation_function The function to use on the hourly groups.
#' @param na.rm a logical value indicating whether NA values should be stripped
#'   before the computation proceeds
#'
#' @return Files with a daily resolution
#' @export
#'

daily_aggregation <- function(folder_in,
                              folder_out,
                              pattern = ".txt$",
                              col_name = "20020101",
                              from = '2002-01-01 00',
                              to = '2021-05-31 23',
                              aggregation_function = mean,
                              na.rm = FALSE){

  hourly_files <- list.files(folder_in,
                             full.names = TRUE,
                             pattern = pattern)

  file_name <- function(x){
    stringr::str_extract(x, "[a-z_]+[0-9]+")
  }
  # date
  my_ymdh <- seq(from = lubridate::ymd_h(from),
                 to = lubridate::ymd_h(to),
                 by = 'hours')

  by_ydm <- lubridate::as_date(my_ymdh)

  # transformation
  pb <- txtProgressBar(min = 0, max = length(hourly_files), style = 3)

  for (i in seq_along(hourly_files)) {

    temp_tbl <- data.table::fread(hourly_files[i], header = TRUE)[-1] #TODO: make this optional!
    temp_tbl <- dplyr::mutate(temp_tbl, date = my_ymdh,
                              day = by_ydm)
    temp_tbl <- dplyr::group_by(temp_tbl, day)
    temp_tbl <- dplyr::summarise(temp_tbl,
                                 daily_mean = aggregation_function(.data[[col_name]],
                                                                   na.rm = na.rm))
    names(temp_tbl)[2] <- col_name

    #saving to file
    data.table::fwrite(temp_tbl[, 2],
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




#' Create a daily dataset with the last observed hourly value
#'
#'
#' This function allows to transform an hourly observed time series to a daily
#' one. Here the returned value is the last observed. This functionality serves
#' to series with hourly frequency where the value of each hour represents the
#' sum accumulated so far, thus, the last value represents the daily sum.
#'
#'
#' @param folder_in Path of the input files
#' @param folder_out Path where to save the transformed files
#' @param col_name The column name for the tables on the output. Usually, the
#'   first date of the time series.
#' @param from The first date of the series, including the hour part.
#' @param to The last date of the series, including the hour part.
#' @param pattern an optional regular expression. Only file names which match
#'   the regular expression will be returned.
#'
#' @return Files with a daily resolution
#' @export
#'

daily_last_value <- function(folder_in,
                             folder_out,
                             col_name = "20020101",
                             from = '2002-01-01 00',
                             to = '2021-05-31 23',
                             pattern = ".txt$"
                             ){

  hourly_files <- list.files(folder_in,
                             full.names = TRUE,
                             pattern = pattern)

  file_name <- function(x){
    stringr::str_extract(x, "[a-z_]+[0-9]+")
  }
  # date
  my_ymdh <- seq(from = lubridate::ymd_h(from),
                 to = lubridate::ymd_h(to),
                 by = 'hours')

  by_ydm <- lubridate::as_date(my_ymdh)

  # transformation
  pb <- txtProgressBar(min = 0, max = length(hourly_files), style = 3)

  for (i in seq_along(hourly_files)) {

    temp_tbl <- data.table::fread(hourly_files[i], header = TRUE)[-1]
    temp_tbl <- dplyr::filter(dplyr::mutate(temp_tbl,
                                            date = my_ymdh,
                                            day = by_ydm,
                                            hours = as.factor(lubridate::hour(date))),
                              hours == 23)


    #saving to file
    data.table::fwrite(temp_tbl[, 1],
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
#' @param col_name The column name for the tables on the output. Usually, the
#'   first date of the time series.
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
                       col_name = "20020101",
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

  file_name <- function(x){
    stringr::str_extract(x, "[a-z_]+[0-9]+")
  }


  # transformation
  pb <- txtProgressBar(min = 0, max = length(dpt_files), style = 3)

  for (i in seq_along(dpt_files)) {

    temp_dpt <- data.table::fread(dpt_files[i], header = TRUE)

    temp_tas <- data.table::fread(tas_files[i], header = TRUE)

    temp_DT <- data.table::data.table(dpt = temp_dpt,
                                      tas = temp_tas,
                                      m = m_value,
                                      Tn = Tn_value)

    names(temp_DT) <- c("dpt", "tas", "m", "Tn")

    rh_tbl <- temp_DT[, .(rh_values = 100*10^(m*((dpt/(dpt+Tn))-(tas/(tas+Tn)))))]

    names(rh_tbl) <- col_name

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

    ws_tbl <- data.table::data.table(windspeed_values = sqrt((temp_uas)^2 + (temp_vas)^2))

    names(ws_tbl) <- col_name


    #saving to file
    data.table::fwrite(ws_tbl,
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



#' Create a daily maximum and minimum from hourly observations
#'
#' This function allows to make the aggregation of hourly observations to daily
#' ones of a time series. Here the aggregation performed returns the highest
#' \emph{(maximum)} and lowest \emph{(minimum)} observed value for the day.
#'
#' @param folder_in Path of the input files
#' @param folder_out Path where to save the transformed files
#' @param col_name The column name for the tables on the output. Usually, the
#'   first date of the time series.
#' @param from The first date of the series, including the hour part.
#' @param to The last date of the series, including the hour part.
#' @param pattern an optional regular expression. Only file names which match
#'   the regular expression will be returned.
#'
#' @return Files with a daily resolution
#' @export
#'

daily_max_min <- function(folder_in,
                          folder_out,
                          col_name = "20020101",
                          from = '2002-01-01 00',
                          to = '2021-05-31 23',
                          pattern = ".txt$"
                          ){

  hourly_files <- list.files(folder_in,
                             full.names = TRUE,
                             pattern = pattern)

  file_name <- function(x){
    stringr::str_extract(x, "[a-z_]+[0-9]+")
  }
  # date
  my_ymdh <- seq(from = lubridate::ymd_h(from),
                 to = lubridate::ymd_h(to),
                 by = 'hours')

  by_ydm <- lubridate::as_date(my_ymdh)

  # transformation
  pb <- txtProgressBar(min = 0, max = length(hourly_files), style = 3)

  for (i in seq_along(hourly_files)) {

    temp_tbl <- data.table::fread(hourly_files[i], header = TRUE)[-1]

    names(temp_tbl) <- "temperature"

    temp_tbl <- dplyr::mutate(temp_tbl,
                              date = my_ymdh,
                              day = by_ydm)

    temp_tbl <- dplyr::group_by(temp_tbl, day)

    temp_tbl <- dplyr::summarise(temp_tbl,
                                 max = max(temperature),
                                 min = min(temperature))

    temp_tbl <- dplyr::mutate(temp_tbl,
                              max_min = paste(round(max, 3), round(min, 3), sep = ","))

    temp_tbl <- dplyr::select(temp_tbl, max_min)

    names(temp_tbl) <- col_name


    #saving to file
    data.table::fwrite(temp_tbl,
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
#' @param col_name The column name for the tables on the output. Usually, the
#'   first date of the time series.
#' @param pattern an optional regular expression. Only file names which match
#'   the regular expression will be returned.
#' @param FUN The function to use for transforming the unit of the variable on
#'   input.
#'
#' @return Files with the same temporal resolution as the input
#' @export
#'

unit_converter <- function(folder_in,
                           folder_out,
                           col_name = "20020101",
                           pattern = ".txt$",
                           FUN = \(x) (x-273.15)
){

  files_list <- list.files(folder_in,
                           full.names = TRUE,
                           pattern = pattern)

  file_name <- function(x){
    stringr::str_extract(x, "[a-z_]+[0-9]+")
  }

  # transformation
  pb <- txtProgressBar(min = 0, max = length(files_list), style = 3)

  for (i in seq_along(files_list)) {

    temp_tbl <- data.table::fread(files_list[i], header = TRUE)

    names(temp_tbl) <- "values"

    temp_tbl <- temp_tbl[, .(converted = FUN(values))]

    names(temp_tbl) <- col_name

    #saving to file
    data.table::fwrite(temp_tbl,
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
#' @examples
summary_table <- function(var_folder,
                          sample = 5,
                          percent = FALSE,
                          by_month = TRUE,
                          from = '2002-01-01',
                          to = '2021-05-31',
                          pattern = ".txt$"
){

  daily_files <- list.files(var_folder,
                            full.names = TRUE,
                            pattern = pattern)

  total_files <- length(daily_files)


  if (percent) {
    sample_val <- round(total_files * sample / 100)
  } else {
    sample_val <- sample
  }

  print(glue::glue("Ok, {sample_val} files will be processed!\n\n"))

  if (by_month) {

    # date
    my_ymd <- seq(from = lubridate::ymd(from),
                  to = lubridate::ymd(to),
                  by = 'day')

    bind_tbl <- do.call(rbind,
                        lapply(sample(seq_len(total_files),
                                      sample_val),
                               function(x) {
                                 temp_file <- daily_files[x]
                                 temp_tbl <- data.table::fread(temp_file, header = TRUE)

                                 names(temp_tbl) <- "month_values"

                                 temp_tbl <- dplyr::mutate(temp_tbl,
                                                           date = my_ymd,
                                                           month_val = as.factor(lubridate::month(date,
                                                                                                  label = TRUE))
                                 )}))

    unique_tbl <- bind_tbl %>%
      dplyr::group_nest(Month = month_val) %>%
      dplyr::mutate(min = lapply(data, \(x)(min(x$month_values))),
                    max = lapply(data, \(x)(max(x$month_values))),
                    mean = lapply(data, \(x)(mean(x$month_values))),
                    sd = lapply(data, \(x)(sd(x$month_values))),
                    n = lapply(data, \(x)(length(x$month_values)))
      ) %>%
      dplyr::select(-data) %>%
      tidyr::unnest(c(min, max, mean, sd, n))

    return(unique_tbl)

  } else {
    temp_tbl <- do.call(rbind,
                        lapply(sample(seq_len(total_files),
                                      sample_val),
                               function(x) {
                                 temp_file <- daily_files[x]
                                 data.table::fread(temp_file, header = TRUE)}))

    names(temp_tbl) <- "all_values"

    unique_tbl <- temp_tbl %>%
      summarise(min = min(all_values),
                max = max(all_values),
                mean = mean(all_values),
                sd = sd(all_values),
                n = length(all_values))

    return(unique_tbl)
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

summary_plot <- function(var_folder,
                         sample = 5,
                         percent = FALSE,
                         from = '2002-01-01',
                         to = '2021-05-31',
                         x_lab = "Months of observation",
                         y_lab = "Vriable name and unit",
                         pattern = ".txt$"
){

  daily_files <- list.files(var_folder,
                            full.names = TRUE,
                            pattern = pattern)

  total_files <- length(daily_files)


  file_name <- function(x){ #TODO: transform to extern function
    stringr::str_extract(x, "[a-z_]+[0-9]+")
  }

  # date
  my_ymd <- seq(from = lubridate::ymd(from),
                to = lubridate::ymd(to),
                by = 'day')

  one_file <- function(file){
    temp_file <- daily_files[file]
    temp_tbl <- dplyr::mutate(data.table::fread(temp_file, header = TRUE),
                              date = my_ymd,
                              month_val = as.factor(lubridate::month(date,
                                                                     label = TRUE)),
                              var_file = file_name(temp_file))
    names(temp_tbl)[1] <- "all_values"
    temp_tbl
  }

  if (percent){
    sample_val <- round(total_files * sample / 100)
  } else {
    sample_val <- sample
  }

  print(glue::glue("Ok, {sample_val} files will be processed!\n\n"))

  # dataset preparation
  data_set <- do.call(rbind,
                      lapply(sample(seq_len(total_files),
                                    sample_val),
                             one_file))
  # ploting
  ggplot2::ggplot(data = data_set,
                  ggplot2::aes(month_val, all_values)) +
    ggplot2::geom_boxplot() +
    ggplot2::labs(x = x_lab,
                  y = y_lab)
}




