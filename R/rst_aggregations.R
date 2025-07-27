#' Create a daily aggregation from an hourly datacube
#'
#' https://confluence.ecmwf.int/display/CKB/ERA5+family+post-processed+daily+statistics+documentation
#'
#' `datacube_aggregation()` aggregates a datacube by a given function. The function will be applied to each
#' day of the datacube.
#'
#' @param input_path Path to the datasetcube
#' @param output_filename Path to the output file
#' @param fun Function to apply to the datasetcube (default is sum). The function
#'  must be a function that takes a vector as input and returns a single value.
#'  See [terra::tapp()] for more information.
#' @param cores Number of cores to use for the aggregation. Default is 1. See
#'  [terra::tapp()] for more information.
#'  See [terra::tapp()] for more information.
#' @param ... Additional arguments to pass to [names_to_date()]
#'
#' @return A raster object with the aggregated data
#'
#' @seealso [terra::tapp()], [names_to_date()]
#'

datacube_aggregation <- function(
    input_path,
    output_filename = "",
    fun = sum,
    cores = 1,
    ...) {
  cube_i <- input_raster(input_path)

  timestamp <- names_to_date(cube_i, ...)

  # index <- as.Date(timestamp)
  index <- "days"

  terra::time(cube_i, tstep = "") <- timestamp

  agg_raster <- terra::tapp(
    x = cube_i,
    index = index,
    fun = fun,
    cores = cores,
    filename = output_filename,
    overwrite = TRUE
  )

  if (output_filename != "") {
    return(agg_raster)
  }
}
