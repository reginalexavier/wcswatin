#' Main table constructor by Variable
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
main_input_var <- function(study_area, var_name = "temp") {
  main_tbl <- data.table::copy(input_table(study_area))

  cols <- c("ID", "NAME", "LAT", "LON", "ELEVATION") # nolint: assignment_linter

  main_tbl[, NAME := paste0(var_name, "_", ID)]

  main_tbl[, ..cols]
}


#' Main table creator for SWAT Input from Trend SUrface Interpolation
#'
#' This function is to create the main table for the input table for SWAT.
#'
#' @param targeted_points_path  Shapefile path
#' @param var_name The variable name
#' @param col_elev The column contain the elevation values
#'
#' @return A table
#' @export
#'
#' @examples
#' var_main_creator(targeted_points_path = system.file("extdata/sl_centroides",
#'   "Centroide_watershed_grau.shp",
#'   package = "wcswatin"
#' ))
var_main_creator <- function(
  targeted_points_path,
  var_name = "pcp",
  col_elev = "Elev"
) {
  targeted_points <- sf::read_sf(targeted_points_path)
  points <- as.data.frame(sf::st_coordinates(targeted_points))
  dplyr::tibble(
    ID = targeted_points$OBJECTID,
    NAME = paste0(var_name, seq_len(nrow(targeted_points))),
    LAT = points$Y,
    LONG = points$X,
    ELEVATION = targeted_points[[col_elev]]
  )
}
