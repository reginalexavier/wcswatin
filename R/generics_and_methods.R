#' Input Raster
#'
#' Method to load ncdf or tiff file and convert them into a SpatRaster object.
#'
#' @param x path (character) to the file or a SpatRaster object.
#' @param \dots  additional arguments to \code{terra::\link[terra]{rast}}.
#'
#' @return SpatRaster
#'
#' @importClassesFrom terra SpatRaster
#'
#' @importFrom methods setGeneric setMethod
#'
#' @seealso \code{terra::rast}
#'
#'
#' @name input_raster
#' @exportMethod input_raster
#'

methods::setGeneric(name = "input_raster",
                    def = function(x, ...) {
                      standardGeneric("input_raster")
                      }
                    )


# S4 method for signature 'character'
#' @rdname input_raster
#' @aliases character-raster
methods::setMethod("input_raster", methods::signature(x = "character"),
                   function(x, ...) {

                     if (tools::file_ext(x) %in% c("nc", "nc4", "tif")) {

                       return(terra::rast(x, ...))

                     } else  {
                         stop("The file extension is not supported. Please, use a nc or tif file.")
                       }

                     }
)



# S4 method for signature 'SpatRaster'
#' @rdname input_raster
#' @aliases SpatRaster
methods::setMethod("input_raster", methods::signature(x = "SpatRaster"),
                   function(x, ...) {

                     return(x)

                   }
)

# S4 method for signature 'RasterLayer'
#' @rdname input_raster
#' @aliases RasterLayer
methods::setMethod("input_raster", methods::signature(x = "RasterLayer"),
                   function(x, ...) {

                     return(terra::rast(x, ...))

                   }
)


# S4 method for signature 'RasterBrick'
#' @rdname input_raster
#' @aliases RasterBrick
methods::setMethod("input_raster", methods::signature(x = "RasterBrick"),
                   function(x, ...) {

                     return(terra::rast(x, ...))

                   }
)


# S4 method for signature 'RasterStack'
#' @rdname input_raster
#' @aliases RasterStack
methods::setMethod("input_raster", methods::signature(x = "RasterStack"),
                   function(x, ...) {

                     return(terra::rast(x, ...))

                   }
)




#' Input Vector
#'
#' Method to load a vector file and convert it into a SpatVector object.
#'
#' @param x path (character) to the file or a SpatVector object.
#' @param \dots  additional arguments to \code{terra::\link[terra]{vect}}.
#'
#' @return SpatVector
#'
#' @importClassesFrom terra SpatVector
#'
#' @seealso \code{terra::vect}
#' @keywords internal
#'
#' @name input_vector
#' @rdname input_vector
#' @exportMethod input_vector

methods::setGeneric(name = "input_vector",
                    def = function(x, ...) {
                      standardGeneric("input_vector")
                      }
                    )

# S4 method for signature 'character'
#' @rdname input_vector
#' @aliases character-vector
methods::setMethod("input_vector", methods::signature(x = "character"),
          function(x, ...) {

            if (tools::file_ext(x) %in% c("shp", "gpkg")) {

              return(terra::vect(x, ...))

            } else  {
              stop("The file extension is not supported. Please, use a shp or gpkg file.")
            }

          }
)

# S4 method for signature 'SpatVector'
#' @rdname input_vector
#' @aliases SpatVector
methods::setMethod("input_vector", methods::signature(x = "SpatVector"),
          function(x, ...) {

            return(x)

          }
)

# S4 method for signature 'sf'
#' @rdname input_vector
#' @aliases sf
methods::setMethod("input_vector", methods::signature(x = "sf"),
          function(x, ...) {

            return(terra::vect(x, ...))

          }
)



#' Input Table
#'
#' Method to load a table file and convert it into a data.table object.
#'
#' @param x path (character) to the file or a data.table object.
#' @param \dots  additional arguments to \code{data.table::fread}.
#'
#' @return data.table
#'
#' @importClassesFrom data.table data.table
#'
#' @seealso \code{data.table::fread}
#'
#' @name input_table
#' @rdname input_table
#' @keywords internal
#'
#' @exportMethod input_table
#'
#'
methods::setGeneric(name = "input_table",
                    def = function(x, ...) {
                      standardGeneric("input_table")
                      }
                    )



# S4 method for signature 'character'
#' @rdname input_table
#' @aliases character-table
methods::setMethod("input_table", methods::signature(x = "character"),
          function(x, ...) {

            if (tools::file_ext(x) %in% c("csv", "txt")) {

              return(data.table::fread(x, ...))

            } else  {
              stop("The file extension is not supported. Please, use a csv or txt file.")
            }

          }
)



# S4 method for signature 'data.table'
#' @rdname input_table
#' @aliases data.table
methods::setMethod("input_table", methods::signature(x = "data.table"),
          function(x, ...) {

            return(x)

          }
)


# S4 method for signature 'data.frame' or 'tibble'
#' @rdname input_table
#' @aliases data.frame
methods::setMethod("input_table", methods::signature(x = "data.frame"),
          function(x, ...) {

            return(data.table::as.data.table(x))

          }
)





