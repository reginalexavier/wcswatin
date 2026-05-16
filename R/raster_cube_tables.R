# os valores da camada raster são extraidos e guardado em uma tabela com as
# colunas values e layer_name. O pixel extraido é identificado pelo ID (row e
# col), o layer_name representa a data da coleta do dado.
# Todas as camadas são empilhadas em uma tabela unica, cada camada é
# diferenciada pela coluna layer_name contendo a data da coleta do dado.

#' Convert a Cube format data into a Table format
#'
#' The function extracts the values of a NetCDF/raster layer and converts it to
#' a table format containing the values of the pixels and the layer name as two
#' columns. The pixel is identified by the ID `(row and col)`, and the layer
#' name represents the date of the data collected. All layers are stacked in a
#' single table, each layer is differentiated by the column layer_name
#' containing the date of the data collected. The function, due to the large
#' amount of data, counts with the structure of parallel processing based on the
#' future package to speed up the process. By default, the computation is done
#' in sequential mode `future::plan(future::sequential)`, for parallel
#' processing, the user must change to the desired mode (ex:
#' future::plan(future::multisession, workers = 6)).
#'
#'
#'
#' @param input_path Path to the NetCDF or raster file.
#' @param var The variable to be extracted. The default is NA. For NetCDF files
#'   containing multiple variables, the user must provide the name of the
#'   variable to be extracted. If the file contains only one variable, the user
#'   can leave this argument as NA.
#' @param n_layers Number of layers in the raster file to be extracted
#' @param study_area The table from 'study_area_records'
#' @param future_scheduling Controling how the future will be scheduled and
#'   distributed between the workers. The default is 1, which means that the
#'   future will be scheduled by core. See the documentation of future package
#'   for more details [future.apply::future_lapply()].
#' @param missing_value The value to be used when the data is missing
#' @param final_dir The directory to save the final table. If NULL, the final
#'   table will not be saved.
#' @param side_effect The side effect of the function. The default is "only",
#'   which means that the function will only save the final table in disk (if
#'   final_dir is provided). The other options are "both" and "none". If "both",
#'   the function will save the final table in disk and return it within the R
#'   environment. If "none", the function will only return the final table
#'   whithin the R environment.
#' @param temp_dir The directory to save the intermediate tables. If the
#'   directory already exists, the tables will be saved in the existing
#'   directory. If the directory does not exist, it will be created. If NULL,
#'   the tables will be saved in a temporary directory.
#' @param clean_after Logical. If TRUE, the directory with the intermediate
#'   tables will be deleted after the process is finished. If FALSE, the
#'   directory will be kept. The default is FALSE. And when the temp_dir is
#'   NULL, what implies that the tables will be saved in a temporary directory,
#'   the temp_dir will be deleted after the process is finished.
#'
#' @return A table containing the:
#'   * ID: The pixel ID (row and col);
#'   * values: The values of the pixel;
#'   * layer_name: The layer name (date of the data collected).
#'
#' @export
#'
cube2table <- function(
  input_path, # cube2table_by_layer
  var = NA,
  n_layers,
  study_area,
  future_scheduling = 1,
  missing_value = -99,
  final_dir = NULL,
  side_effect = "only",
  temp_dir = NULL,
  clean_after = FALSE
) {
  side_effect <- match.arg(side_effect, c("only", "both", "none"))
  validate_positive_whole_number(n_layers, "n_layers")
  validate_scalar_logical(clean_after, "clean_after")

  if (!is.null(final_dir)) {
    validate_scalar_character(final_dir, "final_dir")
  }
  if (!is.null(temp_dir)) {
    validate_scalar_character(temp_dir, "temp_dir")
  }

  if (side_effect != "none" && is.null(final_dir)) {
    stop(
      "The argument 'final_dir' must be provided ",
      "when 'side_effect' is 'only' or 'both'." # nolint: line_length_linter.
    )
  }

  study_area <- input_table(study_area)
  if (!"ID" %in% names(study_area)) {
    stop("The argument 'study_area' must contain an 'ID' column.")
  }
  roi_id <- study_area$ID

  if (is.null(temp_dir)) {
    temp_dir <- file.path(tempdir(), "cube2table")
    clean_after <- TRUE
  }

  touch_dir(temp_dir)

  if (!is.null(final_dir)) {
    touch_dir(final_dir)
  }

  message("The intermediate tables will be saved in: ", temp_dir, "\n")
  if (!is.null(final_dir)) {
    message("The final table will be saved in: ", final_dir, "\n")
  }

  message(
    "Step: Extraction - started at: ",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )

  p <- progressr::progressor(steps = n_layers)

  future.apply::future_lapply(
    X = seq_len(n_layers),
    FUN = function(x) {
      p()
      raster_i <- input_raster(input_path, subds = var, lyrs = x)
      raster_name_i <- names(raster_i)

      cell_values <- terra::values(raster_i)[roi_id]
      # filling missing data with -99
      cell_values[is.na(cell_values)] <- missing_value

      tbl_i <- data.table::data.table(
        ID = roi_id,
        values = cell_values,
        layer_name = raster_name_i
      )

      # save the table
      data.table::fwrite(
        tbl_i,
        file.path(temp_dir, paste0("tbl_", x, ".csv")),
        row.names = FALSE
      )

      # remove the table from memory
      rm(tbl_i)

      tbl_i <- NULL
    },
    future.scheduling = future_scheduling,
    future.packages = c("terra", "dplyr")
  )

  # read the tables
  message(
    "Step: Reading and joining tables at ",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    "\n"
  )

  tbl_files <- file.path(temp_dir, paste0("tbl_", seq_len(n_layers), ".csv"))

  tbl_list <- lapply(
    tbl_files,
    data.table::fread
  )

  if (clean_after) {
    unlink(temp_dir, recursive = TRUE)
  }

  binded_tbl <- do.call(rbind, tbl_list)

  if (side_effect == "none") {
    return(binded_tbl)
  } else if (side_effect == "both") {
    data.table::fwrite(
      binded_tbl,
      file.path(final_dir, "tbls.csv"),
      row.names = FALSE
    )
    return(binded_tbl)
  } else if (side_effect == "only") {
    data.table::fwrite(
      binded_tbl,
      file.path(final_dir, "tbls.csv"),
      row.names = FALSE
    )
  }
  message(
    "Step: Finished at ",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    "\n\n"
  )
}


#' Series of Pixel Values
#'
#' Converts layer-wise values from `cube2table()` into SWAT-style input:
#' a time series for each pixel in the study area.
#'
#' @name layervalues2pixel
#' @rdname layervalues2pixel
#'
#' @param layer_values List. Values extracted per raster layer (from
#'   `cube2table()`).
#' @param main_tbl A table with pixel metadata (e.g., from
#'   `main_input_var()`), used to name each output table.
#' @param col_name Column name for each SWAT input table. Typically the first
#'   date in the time series (e.g., "20220101").
#' @param inline_output Logical. If TRUE, returns a list of data.tables.
#' @param path_output Directory to write one file per pixel when
#'   `inline_output = FALSE`.
#' @param append Logical. If TRUE, append to existing files; otherwise
#'   overwrite.
#'
#' @return A list of tables (when `inline_output = TRUE`) or a set of files in
#'   `path_output` (one for each pixel).
#' @export
#'
#' @examples
#' \dontrun{
#' # Example (pseudo-code):
#' # lv <- cube2table(input_path, var = "tmin", n_layers = 10, study_area)
#' # mt <- main_input_var(study_area, var_name = "tmin")
#' # out <- layervalues2pixel(lv, mt, col_name = "20220101",
#' #                         inline_output = TRUE)
#' }
layervalues2pixel <- function(
  # nolint: object_name_linter
  layer_values,
  main_tbl,
  col_name = "20220101",
  inline_output = TRUE,
  path_output = NULL,
  append = FALSE
) {
  validate_scalar_logical(inline_output, "inline_output")
  validate_scalar_logical(append, "append")

  if (is.null(path_output) && !inline_output) {
    stop(
      "The argument 'inline_output' is FALSE, so the argument ",
      "'path_output' must be provided."
    )
  }

  if (!is.null(path_output)) {
    validate_scalar_character(path_output, "path_output")
    # TODO: uso de dir.create??
    if (!dir.exists(path_output)) {
      dir.create(path_output, recursive = TRUE)
    }
  }

  input_tbl <- input_table(layer_values)
  tb_name <- input_table(main_tbl)$NAME
  if (!all(c("values") %in% names(input_tbl))) {
    stop("The argument 'layer_values' must contain a 'values' column.")
  }
  if (is.null(tb_name)) {
    stop("The argument 'main_tbl' must contain a 'NAME' column.")
  }

  n_row <- length(tb_name)
  n_col <- nrow(input_tbl) / n_row
  if (n_row == 0 || nrow(input_tbl) %% n_row != 0) {
    stop(
      "The number of rows in 'layer_values' must be a multiple of the ",
      "number of rows in 'main_tbl'."
    )
  }
  n_layers <- 1

  m_array <- input_tbl$values |>
    array(dim = c(n_row, n_col, n_layers)) # row col layer

  final_list <- lapply(seq_along(tb_name), \(x) {
    df <- data.table::data.table(m_array[x, , 1]) # row col layer
    colnames(df) <- col_name
    df
  })

  names(final_list) <- tb_name

  if (!is.null(path_output)) {
    for (i in tb_name) {
      data.table::fwrite(
        final_list[[i]],
        stringr::str_glue("{path_output}/{i}.txt"),
        row.names = FALSE,
        dec = ".",
        sep = ",",
        quote = FALSE,
        append = append
      )
    }

    if (inline_output) {
      final_list
    }
  } else {
    final_list
  }
}
