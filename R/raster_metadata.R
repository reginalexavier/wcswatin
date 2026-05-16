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
