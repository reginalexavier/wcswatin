utils::globalVariables(c("study_area", "..cols", "ID", "nome"))

#' Study Area Records
#'
#' This function extracts the records position grid for the study area combining
#' with the DEM for every point
#'
#' @param raster_model One layer representing where the data wile be extracted
#' @param roi A shapefile delimiting the study area
#' @param dem An elevation raster for the study area
#'
#' @return A table
#' @export
#'
study_area_records <- function(raster_model,
                               roi,
                               dem){

  raster_model <- input_raster(raster_model, lyrs = 1)
  roi <- input_vector(roi)
  dem <- input_raster(dem)
  #obtain cell numbers within the raster_model
  roi_cell <- raster_model |>
    terra::mask(roi |>
                  terra::project(terra::crs(raster_model))) |>
    terra::values(mat = FALSE)


  roi_cell <- which(!is.na(roi_cell))

  #obtain lat/long values corresponding to watershed cells
  cell_longlat <- terra::xyFromCell(raster_model, roi_cell)
  cell_rowCol <- terra::rowColFromCell(raster_model, roi_cell)
  points_elevation <- terra::extract(x = dem,
                                     y = cell_longlat,
                                     method = 'simple')$elevation

  study_area_records <- data.table::data.table(cell_longlat,
                                               ID = roi_cell,
                                               cell_rowCol,
                                               Elevation = points_elevation
  )

  names(study_area_records) <- c("x", "y", "ID", "row", "col", "Elevation")

  study_area_records

}


#' Main table contructor by Variable
#'
#' Construct a main table needed for the input in SWAT
#'
#'
#' @param study_area The object from 'study_area_records'
#' @param var_name The name of the variable to be extracted
#'
#' @return A table
#' @export
#'
mainInput_var <- function(study_area, var_name = "temp"){

  main_tbl <- data.table::copy(study_area)

  cols <- c("ID", "NAME", "LAT", "LONG", "ELEVATION")

  main_tbl[, nome := paste0(var_name,"_", ID)]
  data.table::setnames(main_tbl, c("ID", "nome", "y", "x", "Elevation"), cols)

  main_tbl[ , ..cols]

}

# os valores da camada raster são extraídos e guardado em uma tabela com as colunas
# values e layer_name. O pixel extraido é identificado pelo ID (row e col), o layer_name
# representa a data da coleta do dado.
# Todas as camadas são empilhadas em uma tabela unica, cada camada é diferenciada pela coluna
# layer_name contendo a data da coleta do dado.



#' Convert a Raster Layer to a Vector
#'
#' The function extracts the values of a NetCDF/raster layer and converts it to a table format
#' containing the values of the pixels and the layer name as two columns. The pixel is identified
#' by the ID (row and col), and the layer name represents the date/hour of the data collected.
#' All layers are stacked in a single table, each layer is differentiated by the column layer_name
#' containing the date of the data collected.
#' The function, due to the large amount of data, counts with the structure of parallel processing
#' based on the future package to speed up the process. By default, the computation is done in
#' sequential mode (future::plan(future::sequential)), for parallel processing, the user must
#' change to the desired mode (ex: future::plan(future::multisession, workers = 6)).
#'
#'
#'
#' @param raster_path Raster file or path to a raster/ncdf file
#' @param var The variable to be extracted
#' @param n_layers Number of layers in the raster file to be extracted
#' @param study_area The table from 'study_area_records'
#' @param future_scheduling Controling how the future will be scheduled and distributed
#'  between the workers. The default is 1, which means that the future will be scheduled
#'  by core. See the documentation of future package for more details \code{future.apply::future_lapply}
#' @param missing_value The value to be used when the data is missing
#'
#' @return A table
#' @export

raster2vec <- function(raster_path,
                       var = NA,
                       n_layers,
                       study_area,
                       future_scheduling = 1,
                       missing_value = -99){

  p <- progressr::progressor(steps = n_layers) # steps = n_layers

  roi_id <- input_table(study_area)$ID

  tbl_list <- future.apply::future_lapply(

    X = seq_len(n_layers),
    FUN = function(x){
      p()
      raster_i <- input_raster(raster_path,
                               subds = var,
                               lyrs = x)
      raster_name_i <- names(raster_i)

      cell.values <- terra::values(raster_i)[roi_id]
      cell.values[is.na(cell.values)] <- missing_value #filling missing data with -99

      data.table::data.table(ID = roi_id,
                             values = cell.values,
                             layer_name = raster_name_i)
    },

    # SIMPLIFY = FALSE,
    future.scheduling = future_scheduling,
    # future.seed = NULL,
    future.packages = c("terra", "dplyr")
  )

  do.call(rbind, tbl_list)
}



#' Series of Pixel Values (table format)
#'
#' With the extracted values by raster layer from the (raster2vec) function, this function
#' organize these values in the format of swat input, i.e, a time serie for every pixel
#' of the study area.
#'
#' @param layer_values List. Values extracted by raster
#' @param tb_name A vector contain the names for every table created. These names are
#' in the mainTable
#' @param col_name A name for the column of everery swatinput table created. Commonly this
#' name is the first date of time serie beeing analysed.
#'
#' @return A list of table
#' @export
#'
layerValues2pixel <- function(layer_values,
                              tb_name,
                              col_name = "20020101"){

  input_tbl <- input_table(layer_values)

  tbl_list <- split(input_tbl[, c("values", "layer_name")], by = "layer_name", keep.by = F)

  transposed_tbl <- data.table::transpose(data.table::as.data.table(tbl_list))

  final_list <- lapply(as.list(transposed_tbl),
                       \(x) {
                         df <- data.table::data.table(x)
                         colnames(df) <- col_name
                         df
                       }
  )

  names(final_list) <- tb_name

  final_list

}




#' Series of Pixel Values (Array Format)
#'
#' With the extracted values by raster layer from the (raster2vec) function, this function
#' organize these values in the format of swat input, i.e, a time serie for every pixel
#' of the study area.
#'
#' @param layer_values List. Values extracted by raster
#' @param tb_name A vector contain the names for every table created. These names are
#' in the mainTable
#' @param col_name A name for the column of everery swatinput table created. Commonly this
#' name is the first date of time serie beeing analysed.
#'
#' @return A list of table
#' @export
#'
layerValues2pixelA <- function(layer_values,
                               tb_name,
                               col_name = "20020101"){


  input_tbl <- input_table(layer_values)

  n_row <- length(tb_name)
  n_col <- nrow(input_tbl)/n_row
  n_layers <- 1

  m_array <- input_tbl$values |>
    array(dim = c(n_row, n_col, n_layers)) # row col layer

  final_list <- lapply(seq_along(tb_name),
         \(x) {
           df <- data.table::data.table(m_array[ x, , 1]) # row col layer
           colnames(df) <- col_name
           df
         }
  )

  names(final_list) <- tb_name

  final_list

}



