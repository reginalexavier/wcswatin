utils::globalVariables(c(
  ".",
  "all_values",
  "data",
  "day",
  "dpt",
  "hours",
  "max_min",
  "month_val",
  "sd",
  "tas",
  "temperature",
  "value",
  "..i"
))


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
  files_name <- list.files(files_path, full.names = FALSE)

  point_list <- lapply(
    glue::glue(
      "{files_path}/{grep(files_pattern,
                                files_name, value = TRUE)}"
    ),
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
    from = as.Date(start_date, format = "%Y-%m-%d"),
    to = as.Date(end_date, format = "%Y-%m-%d"),
    by = interval
  )

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

#' Transforms the raw value from point perspective to a daily perspective
#'
#' Having the collected observation from a point perspective, this function
#' transform the input to a vertical perspective, like a a daily perspective.
#'
#' @param my_folder character. The path to the raw files.
#' @param var_pattern character. A pattern for the observation/station points
#' name.
#' @param main_pattern character. A pattern for the main file  containing all
#' the points with ID, NAME, LAT, LONG and ELEVATION.
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
  negatif_number = TRUE,
  prefix = "day_"
) {
  files_name <- list.files(my_folder, full.names = FALSE)

  pcp <- data.table::fread(
    glue::glue(
      "{my_folder}/{grep(main_pattern,
                                                files_name,
                                                value = TRUE)}"
    ),
    header = TRUE
  )

  point_list <- lapply(
    glue::glue(
      "{my_folder}/{grep(var_pattern,
                                                files_name,
                                                value = TRUE)}"
    ),
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
    from = as.Date(start_date, format = "%Y%m%d"), # FIXME
    # FIXME colocar no padrão igual a primeira função
    to = as.Date(end_date, format = "%Y%m%d"),
    by = interval
  )

  # juntando as precipitaçoes em uma tabela só
  cplt_tbl <- do.call(cbind, point_list)
  colnames(cplt_tbl) <- names_sans_ext
  cplt_tbl <- dplyr::as_tibble(cplt_tbl) %>% dplyr::mutate(ymd = datas)

  # setar valores inferios a -99 para Nan
  if (!is.na(na_value)) {
    cplt_tbl <- dplyr::mutate_if(cplt_tbl, is.numeric, function(x) {
      ifelse(x == na_value, NaN, x)
    })
  } else {
    cplt_tbl
  }

  # setar valores inferios a 0 para zero
  if (negatif_number) {
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
#' @export
#'
#' @examples
#' \donttest{
#' temp <- tempdir()
#' folder <- system.file("extdata/pcp_stations", package = "wcswatin")
#' test01 <- point_to_daily(my_folder = folder)
#' save_daily_tbl(
#'   tbl_list = test01,
#'   path = temp
#' )
#' unlink(temp, recursive = TRUE)
#' }
save_daily_tbl <- function(tbl_list, path) {
  for (i in seq_along(tbl_list)) {
    data.table::fwrite(
      tbl_list[[i]], # excluindo a coluna de data
      file = glue::glue("{path}/{names(tbl_list[i])}.csv")
    )
  }
}


#' Shows the variables present in a netcdf
#'
#' @param path Path where the netcdf file is located
#'
#' @return List of variable names
#' @export
#'
var_names <- function(path) {
  lapply(path, function(x) {
    names(ncdf4::nc_open(x)$var)
  }) |>
    unlist()
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
tbl_from_references <- function(
  raster_file,
  ref_points,
  prefix_colname = NULL,
  ...
) {
  if ("sf" %in% class(ref_points)) {
    ref_points <- ref_points
  } else if ("data.frame" %in% class(ref_points)) {
    ref_points <- sf::st_as_sf(
      ref_points,
      coords = c("LONG", "LAT"),
      crs = "+proj=longlat +datum=WGS84 +no_defs"
    )
  } else if (
    "character" %in%
      class(ref_points) &&
      any(stringr::str_ends(ref_points, c(".txt", ".csv")))
  ) {
    tbl_ref <- data.table::fread(ref_points)
    ref_points <- sf::st_as_sf(
      tbl_ref,
      coords = c("LONG", "LAT"), # TODO: rename LONG to LON
      crs = "+proj=longlat +datum=WGS84 +no_defs"
    )
  } else {
    stop(
      "The ref_points must be an object of class `sf`, `data.frame` ",
      "or a string character of the path of a file with ",
      "extension `.csv` or `.txt`!"
    )
  }
  # extração dos  valores nos rasters
  values_extracted <- raster::extract(
    raster_file,
    ref_points,
    ...
  )

  df_extracted <- as.data.frame(t(values_extracted[, -1]), row.names = FALSE)

  if (is.null(prefix_colname)) {
    colnames(df_extracted) <- ref_points$NAME
  } else {
    colnames(df_extracted) <- glue::glue(
      "{prefix_colname}_{ref_points$NAME}"
    )
  }

  df_extracted
}


#' Extract the file name
#'
#' This function extracts the file name without the extension from a file path.
#' It is an internal function used in the \code{unit_converter} function.
#'
#' @param path A character string with the file path.
#'
#' @return A character string with the file name without the extension.
#'
#' @keywords internal
#'
file_name <- function(path) {
  stringr::str_extract(path, "[a-z0-9]+_[0-9]+")
}


#' Create a directory if it does not exist
#'
#' This function creates a directory if it does not exist.
#' It is an internal function used in the \code{unit_converter} function.
#'
#' @param folder_path A character string with the path of the directory to be
#' created.
#' @param return_path logical. If \code{TRUE}, the function returns the path
#'
#' @keywords internal
#'
#' @return NULL. Only for side effects.
#'
touch_dir <- function(folder_path, return_path = FALSE) {
  if (!dir.exists(folder_path)) {
    dir.create(folder_path, recursive = TRUE)
  }
  if (return_path) {
    return(folder_path)
  }
}

#' Clean a directory if it exists
#' This function removes files and/or sub-directory within the
#' directory if exists.
#'
#' @param folder_path A character string with the path of the directory to be
#' cleaned.
#'
#' @keywords internal
#'
#' @return NULL. Only for side effects.
#'
clean_dir <- function(folder_path) {
  if (dir.exists(folder_path)) {
    unlink(folder_path, recursive = TRUE)
  }
}


#' Extract the date from the layer names
#' This function extracts the date from the layer names of a raster object.
#'
#' @param raster_cube A raster object.
#' @param origin A character string with the origin date. The default is
#' "1970-01-01".
#' @param tz A character string with the time zone. The default is "UTC".
#' @param regex A character string with the regular expression to extract the
#' date.
#'
#' @keywords internal
#'
#' @return A POSIXct object.
#'
names_to_date <- function(
  raster_cube,
  origin = "1970-01-01",
  tz = "UTC",
  regex = ".*=(\\d+)"
) {
  layer_names <- names(raster_cube)
  timestamp <- as.numeric(sub(regex, "\\1", layer_names))
  return(as.POSIXct(timestamp, origin = origin, tz = tz))
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

    return(unique_tbl)
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
