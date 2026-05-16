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
  as.POSIXct(timestamp, origin = origin, tz = tz)
}
