#' Transform the raw value from point perspective to a daily perspective
#'
#' Having the collected observation from a point perspective, this function transform the
#' input to a vertical perspective, like a a daily perspective.
#'
#' @param my_folder character. The path to the raw files.
#' @param var_pattern character. A pattern for the observatin/station points name.
#' @param main_pattern character. A pattern for the main file  containing all the
#' points with ID, NAME, LAT, LONG and ELEVATION.
#' @param start_date character. Inform the start date of the serie in the format yyyymmdd.
#' @param end_date character. Inform the end date of the serie in the format yyyymmdd.
#' @param na_value numeric. Value encoded as not available, use \code{NA} for NA.
#' @param interval charactere. Inform the inteval betwenn two observations. See the function x
#' @param prefix character. A prefix for naming the table in the format of "prefix+date".
#' for more detail.
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
                           start_date = "20020101",
                           end_date = "20020120",
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
  datas <- seq.Date(from = as.Date(start_date, format = "%Y%m%d"), # data inicial
                    to = as.Date(end_date, format = "%Y%m%d"), # data final
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



