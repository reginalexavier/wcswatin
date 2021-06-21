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

  for (i in seq_len(raster::nlayers(rasterbrick))) {
    cell.values <- as.vector(rasterbrick[[i]])[study_area$ID]
    cell.values[is.na(cell.values)] <- '-99.0' #filling missing data with -99
    tbl_list[[i]] <- dplyr::tibble(values = as.numeric(cell.values),
                                   layer_name = names(rasterbrick[[i]]))
  }

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
#' NetCDF to Raster
#'
#' @param ncdf_file A ncdf file to be transformed to raster
#' @param var_name The variable to be
#' @param time_step_start The time step for the first datetime
#' @param time_step_end The time step for the last datetime (1 for unique layer
#' e -1 for all see ncdf4::ncvar_get)
#' @param datetime The datetime for the layer
#' @param coordinate_rs The coordinate reference system see sp::CRS()
#'
#' @return A raster
#' @export
ncdf2raster <- function(ncdf_file,
                        var_name = "my_variable",
                        time_step_start = 1,
                        time_step_end = 1,
                        datetime = "2000-01-01",
                        coordinate_rs = sp::CRS('+proj=longlat +datum=WGS84')
                        ){
  nc <- ncdf4::nc_open(ncdf_file)
  ###getting the x values (longitudes in degrees east)
  nc_long <- ncdf4::ncvar_get(nc,
                              c("lon", "longitude")[c("lon", "longitude") %in%
                                                      names(nc$dim)])
  ####getting the y values (latitudes in degrees north)
  nc_lat <- ncdf4::ncvar_get(nc,
                             c("lat", "latitude")[c("lat", "latitude") %in%
                                                    names(nc$dim)])

  # extract values
  start <- rep(1, nc$ndims)
  start[which(rev(names(nc$dim)) %in% "time")] <- time_step_start
  count <- nc$var[[var_name]]$varsize
  count[which(rev(names(nc$dim)) %in% "time")] <- time_step_end
  var_values <- ncdf4::ncvar_get(nc, var_name,
                                 start = start,
                                 count = count
  )
  length(time_step_start:time_step_end)
  # reorder the rows (negative delta, indicando inversão das linhas)
  # stars::read_stars(file_path, var = "precipitationCal")
  # latitude needs reorder????
  if (nc_lat[1] == max(nc_lat) &
      nc_lat[nrow(nc_lat)] == min(nc_lat)) {
    var_values
  } else {
    var_values <- var_values[nrow(var_values):1,]
  }

  # need to reverse rows and columns for consistency???
  if (nrow(var_values) != length(nc_lat) &
      ncol(var_values) != length(nc_long)) {
    var_values <- t(var_values)
  } else {
    var_values
  }


  ncdf4::nc_close(nc)
  #save the daily climate var_values values in a raster
  ncdf_raster <- raster::raster(x = as.matrix(var_values),
                                xmn = min(nc_long),
                                xmx = max(nc_long),
                                ymn = min(nc_lat),
                                ymx = max(nc_lat),
                                crs = coordinate_rs
  )
  names(ncdf_raster) <- datetime
  ncdf_raster
}

