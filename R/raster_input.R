utils::globalVariables(c("study_area"))

#' Study Area Records
#'
#' This function extracts the records position grid for the study area combining
#' with the DEM for every point
#'
#' @param raster One layer representing where the data wile be extracted
#' @param watershed A shapefile delimiting the study area
#' @param DEM An elevation raster for the study area
#'
#' @return A table
#' @export
#'
study_area_records <- function(raster, watershed, DEM){
  #obtain cell numbers within the raster raster
  cell.no <- raster::cellFromPolygon(raster,
                                     rgdal::readOGR(dsn = watershed, verbose = FALSE))
  #obtain lat/long values corresponding to watershed cells
  cell.longlat <- raster::xyFromCell(raster, unlist(cell.no))
  cell.rowCol <- raster::rowColFromCell(raster, unlist(cell.no))
  points_elevation <- raster::extract(x = raster::raster(DEM),
                                      y = cell.longlat,
                                      method = 'simple')

  study_area_records <- data.frame(ID = unlist(cell.no),
                                   cell.longlat,
                                   cell.rowCol,
                                   Elevation = points_elevation
  )

  sp::coordinates(study_area_records) <- ~x+y

  data.frame(sp::coordinates(study_area_records),
             ID = study_area_records$ID,
             row = study_area_records$row,
             col = study_area_records$col,
             Elevation = study_area_records$Elevation
  )
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
mainInput_var <- function(study_area, var_name = "uas"){
  filenameSWAT <- vapply(study_area$ID, function(x){
    paste(var_name, x, sep = '')}, character(1)
  )
  #### Write out the SWAT grid information master table
  outSWAT <- data.frame(ID = study_area$ID,
                        NAME = filenameSWAT,
                        LAT = study_area$y,
                        LONG = study_area$x,
                        ELEVATION = study_area$Elevation
  )
  outSWAT
}


#' Convert a Raster Layer to a Vector
#'
#' Convert a Raster Layer to a Vector
#'
#' @param rasterbrick The raster where the values have to be extracted
#' @param study_area The object from 'study_area_records'
#'
#' @return A named list
#' @export
#'
# obtain daily climate values at cells bounded with the study watershed (extract values from a raster)
# extração de dados em um raster e salvando em um vetor(lista nomeada)
raster2vec <- function(rasterbrick, study_area){
  # cell values by day for all the serie
  tbl_list <- vector(mode = "list", length = raster::nlayers(rasterbrick))

  pb <- txtProgressBar(min = 0, max = raster::nlayers(rasterbrick), style = 3) # including a progress bar

  for (i in seq_len(raster::nlayers(rasterbrick))) {
    cell.values <- as.vector(rasterbrick[[i]])[study_area$ID]
    cell.values[is.na(cell.values)] <- '-99.0' #filling missing data with -99
    tbl_list[[i]] <- dplyr::tibble(values = as.numeric(cell.values),
                                   layer_name = names(rasterbrick[[i]]))
    setTxtProgressBar(pb, i) # the progressbar
  }

  close(pb) # end of the progress bar

  names(tbl_list) <- names(rasterbrick)

  do.call(rbind, tbl_list)

}



#' Series of Pixel Values
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
                              col_name = "20170101000000"){
  tbl_list <- split(layer_values[, 1], layer_values[,2])
  layer_list <- vector(mode = "list", length = length(tbl_list))
  px_list <- vector(mode = "list", length = nrow(tbl_list[[1]])) #length(tbl_list[[1]]))

  pb <- txtProgressBar(min = 0, max = nrow(tbl_list[[1]]), style = 3)
  for (p in seq_len(nrow(tbl_list[[1]]))) { # n pixels
    #pb1 <- txtProgressBar(min = 0, max = length(tbl_list), style = 3)
    for (d in seq_len(length(tbl_list))) { # n days/layers
      layer_list[[d]] <- as.numeric(tbl_list[[d]][p, 1])
      #setTxtProgressBar(pb1, d)
    }
    #close(pb1)
    px_list[[p]] <- data.frame(unlist(layer_list))

    colnames(px_list[[p]]) <- col_name
    setTxtProgressBar(pb, p)
  }

  names(px_list) <-  tb_name # name for every table

  close(pb)

  px_list
}




#' NetCDF to Raster
#'
#' Transformation/convertion of a NetCDF file into a Raster file.
#'
#' @param ncdf_file Character string of the path of the NetCDF file to be
#'   transformed into raster.
#' @param var_name Character string of the variable name to be extracted.
#' @param time_step_end If not NULL, a numeric value for the final time step. When NULL,
#' all the time steps are read if exist in the raw NetCDF file.
#' @param coordinate_rs Character string of the coordinate reference system, see
#'   \code{\link[sp]{CRS}}.
#'
#'
#' @return A raster
#' @export

ncdf_to_raster <- function(ncdf_file,
                           var_name,
                           time_step_end = NULL,
                           coordinate_rs = sp::CRS('+proj=longlat +datum=WGS84')) {
  nc_file <- ncdf4::nc_open(ncdf_file)
  ###getting the x values (longitudes in degrees)
  nc_long <- ncdf4::ncvar_get(nc_file,
                              c("lon", "longitude")[c("lon", "longitude") %in%
                                                      names(nc_file$dim)])
  ####getting the y values (latitudes in degrees)
  nc_lat <- ncdf4::ncvar_get(nc_file,
                             c("lat", "latitude")[c("lat", "latitude") %in%
                                                    names(nc_file$dim)])
  # setting the datetime for the ncdf file
  datetime <-
    as.character(ncdf4.helpers::nc.get.time.series(nc_file,
                                                   v = var_name,
                                                   time.dim.name = "time"))
  if (!is.null(time_step_end)) {
    datetime <- datetime[1:time_step_end]
  }
  # extract values
  var_values <- ncdf4::ncvar_get(nc = nc_file,
                                 varid = var_name)

  if (length(datetime) == 1) {
    # ncdf with one timestep
    if (length(dim(var_values)) == 3) {
      var_values <- var_values[, , 1]
    }
    # latitude needs reorder????
    if (nc_lat[1] == max(nc_lat) &
        nc_lat[nrow(nc_lat)] == min(nc_lat)) {
      var_values
    } else {
      var_values <- var_values[nrow(var_values):1, ]
    }

    # need to reverse rows and columns for consistency???
    if (nrow(var_values) != length(nc_lat) &
        ncol(var_values) != length(nc_long)) {
      var_values <- t(var_values)
    } else {
      var_values
    }

    #save the daily climate var_values values in a raster
    ncdf_raster <- raster::raster(
      x = as.matrix(var_values),
      xmn = min(nc_long),
      xmx = max(nc_long),
      ymn = min(nc_lat),
      ymx = max(nc_lat),
      crs = coordinate_rs
    )


    names(ncdf_raster) <- datetime

    ncdf_raster <- ncdf_raster



  } else {
    # ncdf with multiple timestep

    #transformando o array tridimencional para uma lista de array bidimencional
    val_list <- vector(mode = "list", length = length(datetime))

    for (i in seq_along(datetime)) {
      val_list[[i]] <- var_values[, , i]
    }

    for (i in seq_along(val_list)) {
      # latitude needs reorder????
      if (nc_lat[1] == max(nc_lat) &
          nc_lat[nrow(nc_lat)] == min(nc_lat)) {
        val_list[[i]]
      } else {
        val_list[[i]] <- val_list[[i]][nrow(val_list[[i]]):1, ]
      }

      # need to reverse rows and columns for consistency???
      if (nrow(val_list[[i]]) != length(nc_lat) &
          ncol(val_list[[i]]) != length(nc_long)) {
        val_list[[i]] <- t(val_list[[i]])
      } else {
        val_list[[i]]
      }
    }

    generic_layer <- raster::raster(
      nrows = length(nc_lat),
      ncols = length(nc_long),
      xmn = min(nc_long),
      xmx = max(nc_long),
      ymn = min(nc_lat),
      ymx = max(nc_lat),
      crs = coordinate_rs
    )

    raster_list <- vector(mode = "list", length = length(val_list))

    cat(glue::glue(
      "Transforming {length(val_list)} timesteps into raster layer"
    ))

    # iterate with progress bar
    pb <- txtProgressBar(min = 0,
                         max = length(val_list),
                         style = 3)
    for (i in seq_along(val_list)) {
      raster_list[[i]] <- raster::setValues(generic_layer,
                                            values = val_list[[i]])
      names(raster_list[[i]]) <- datetime[i]
      setTxtProgressBar(pb, i)
    }

    ncdf_raster <- raster::brick(raster_list)

  }

  ncdf4::nc_close(nc_file)

  ncdf_raster
}


