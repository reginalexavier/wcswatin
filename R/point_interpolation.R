

#' Trend Surface Interpolation by Targeded Points
#'
#' This function make an interpolation whith the trend surface method where the user
#' have to inform the polynome degree. The interpolation is made over the tageded points
#' for all the serie on the input.
#'
#' @param my_folder Folder containing the ts input files.
#' @param targeted_points_path A shapefile containing the targeted points where the
#'  trend suface function have to predict values.
#' @param poly_degree The degree to be used in the polynomial function for the trend surface.
#'
#' @return A list of tibles by day
#' @export
#'
#' @importFrom stats as.formula lm predict
#'
#' @examples
#' ts_bypoint(my_folder = system.file("extdata/ts_input", package = "cwswatinput"),
#'           targeted_points_path = system.file("extdata/sl_centroides/Centroide_watershed_grau.shp",
#'            package = "cwswatinput"),
#'           poly_degree = 2)
ts_bypoint <- function(my_folder,
                       targeted_points_path,
                       poly_degree = 2){

  var_files <- list.files(my_folder,
                          full.names = TRUE,
                          pattern = ".csv$")

  temp_name <- list.files(my_folder,
                          full.names = FALSE)

  names_sans_ext <- tools::file_path_sans_ext(temp_name)

  targeted_points <- sf::read_sf(targeted_points_path)

  pcpList <- vector(mode = "list", length = length(var_files)) #blank list for future alocation
  non_zero <- function(x){ifelse(x < 0, 0, x)}

  # iteração com progress bar
  pb <- txtProgressBar(min = 0, max = length(pcpList), style = 3)
  for (i in seq_along(var_files)) {

    pcp_temp <- vroom::vroom((var_files[i]),
                             delim = ",",
                             col_types = "cddddd")

    # o polynomio do modelo
    my_formula <- as.formula(pcp ~ poly(LONG, LAT, degree = poly_degree))

    # ajuste do modelo
    fit_lm <- lm(my_formula, data = pcp_temp)

    # estimando para os pontos de referencia
    target_temp <- dplyr::tibble(LONG = targeted_points$Lon_dec,
                                 LAT = targeted_points$Lat_dec)
    interpolation <- dplyr::mutate(target_temp,
                                   Z = non_zero(predict(fit_lm,
                                                        target_temp)))

    names(interpolation)[3] <- names_sans_ext[i]
    #rename(precipitation, "layer" = substr(var_files[i], 62, 75))

    pcpList[[i]] <- interpolation[3]

    setTxtProgressBar(pb, i)
  }

  close(pb) # fim do bloco

  # renaming the objects list by the date
  names(pcpList) <- names_sans_ext

  # function allowing transformation from a dailly(horizontal) perspective to a
  # centroide(vertical) perspective
  toCentroide <- function(x) {
    all_pcp <- dplyr::mutate(do.call(cbind, x), ID = 1:dplyr::n())

    long_table <- tidyr::pivot_longer(all_pcp, cols = seq_along(all_pcp[-1]),
                                      names_to = "date", values_to = "value")
    split(long_table, long_table$ID)

  }

  ## tabela final ----
  toCentroide(pcpList)

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
#' varMain_creator(targeted_points_path = system.file("extdata/sl_centroides",
#'                "Centroide_watershed_grau.shp",
#'                package = "cwswatinput"))
varMain_creator <- function(targeted_points_path,
                            var_name = "pcp",
                            col_elev = "Elev"){
  targeted_points <- sf::read_sf(targeted_points_path)
  points <- as.data.frame( sf::st_coordinates(targeted_points))
  dplyr::tibble(ID = targeted_points$OBJECTID,
                NAME = paste0(var_name, 1:nrow(targeted_points)),
                LAT = points$Y,
                LONG = points$X,
                ELEVATION = targeted_points[[col_elev]])
}
