#' Trend Surface Interpolation into Targeded Points
#'
#' This function make an interpolation whith the trend surface method where the
#' user have to inform the polynome degree. The interpolation is made over the
#' tageded points for all the serie on the input.
#'
#' @param my_folder Folder containing the ts input files.
#' @param targeted_points_path A shapefile containing the targeted points where
#'  the trend suface function have to predict values.
#' @param poly_degree The degree to be used in the polynomial function for the
#' trend surface.
#'
#' @return A list of tibles by day
#' @export
#'
#' @importFrom stats as.formula lm predict
#'
# @examples
# ts_to_point(my_folder = system.file("extdata/ts_input", package =
#           "wcswatin"), targeted_points_path =
#           system.file("extdata/sl_centroides/centroide_watershed_wgs84.txt",
#           package = "wcswatin"), poly_degree = 2)
ts_to_point <- function(my_folder, targeted_points_path, poly_degree = 2) {
  var_files <- list.files(my_folder, full.names = TRUE, pattern = ".csv$")

  temp_name <- list.files(my_folder, full.names = FALSE)

  names_sans_ext <- tools::file_path_sans_ext(temp_name)

  targeted_points <- sf::read_sf(targeted_points_path)

  pcp_list <- vector(
    mode = "list", # blank list for future alocation
    length = length(var_files)
  )
  non_zero <- function(x) {
    ifelse(x < 0, 0, x)
  }

  # iteration with progress bar
  pb <- txtProgressBar(min = 0, max = length(pcp_list), style = 3)
  for (i in seq_along(var_files)) {
    pcp_temp <- vroom::vroom(
      (var_files[i]),
      delim = ",",
      col_types = "dcdddd"
    )

    # o polynomio do modelo
    my_formula <- as.formula(pcp ~ poly(LONG, LAT, degree = poly_degree))

    # ajuste do modelo
    fit_lm <- lm(my_formula, data = pcp_temp)

    # estimando para os pontos de referencia
    target_temp <- dplyr::tibble(
      LONG = targeted_points$Lon_dec,
      LAT = targeted_points$Lat_dec
    )
    interpolation <- dplyr::mutate(
      target_temp,
      Z = non_zero(predict(
        fit_lm,
        target_temp
      ))
    )

    names(interpolation)[3] <- names_sans_ext[i] # renaming the column

    pcp_list[[i]] <- interpolation[3]

    setTxtProgressBar(pb, i)
  }

  close(pb) # fim do bloco

  # renaming the objects list by the date
  names(pcp_list) <- names_sans_ext

  # function allowing transformation from a dailly(horizontal) perspective to a
  # centroide(vertical) perspective
  to_centroide <- function(x) {
    all_pcp <- dplyr::mutate(
      do.call(cbind, x),
      ID = seq_len(dplyr::n())
    )

    long_table <- tidyr::pivot_longer(
      all_pcp,
      cols = seq_along(all_pcp[-1]),
      names_to = "date",
      values_to = "value"
    )
    split(long_table, long_table$ID)
  }

  ## tabela final ----
  to_centroide(pcp_list)
}


#' Trend Surface Interpolation into Raster
#'
#' This function make an interpolation whith the trend surface method where the
#' user have to inform the polynome degree. The interpolation is made over the
#' tageded points for all the serie on the input.
#'
#' @param my_folder Folder containing the ts input files.
#' @param bassin_limit_path A shapefile containing the bassin limit where the
#' trend suface function have to be predicted.
#' @param poly_degree The degree to be used in the polynomial function for the
#' trend surface.
#' @param resolution The resolution for the output raster in degree.
#'
#' @return A rasterbrick
#' @export
#'
#' @examples
#' ts_to_area(
#'   my_folder = system.file("extdata/ts_input", package = "wcswatin"),
#'   bassin_limit_path = system.file("extdata/sl_bassin/sl_bassin_limit.shp",
#'     package = "wcswatin"
#'   ),
#'   poly_degree = 2,
#'   resolution = 0.5
#' )
ts_to_area <- function(
  my_folder,
  bassin_limit_path,
  poly_degree = 2,
  resolution = 0.01
) {
  bassin_limit <- sf::read_sf(bassin_limit_path)

  var_files <- list.files(my_folder, full.names = TRUE, pattern = ".csv$")

  # temp_name <- list.files(my_folder,
  #                         full.names = FALSE)

  names_sans_ext <- tools::file_path_sans_ext(list.files(
    my_folder,
    full.names = FALSE
  ))

  # blank list for future alocation
  raster_list <- vector(mode = "list", length = length(var_files))
  non_zero <- function(x) {
    ifelse(x < 0, 0, x)
  }

  # template grid
  bbox <- c(
    "xmin" = sf::st_bbox(bassin_limit)[[1]],
    "ymin" = sf::st_bbox(bassin_limit)[[2]],
    "xmax" = sf::st_bbox(bassin_limit)[[3]],
    "ymax" = sf::st_bbox(bassin_limit)[[4]]
  )

  grd_template_sl <- expand.grid(
    LONG = seq(from = bbox["xmin"], to = bbox["xmax"], by = resolution),
    LAT = seq(from = bbox["ymin"], to = bbox["ymax"], by = resolution)
  )

  # iteration with progress bar
  pb <- txtProgressBar(min = 0, max = length(raster_list), style = 3)
  for (i in seq_along(var_files)) {
    pcp_temp <- vroom::vroom(
      (var_files[i]),
      delim = ",",
      col_types = "dcdddd"
    )

    # o polynomio do modelo
    my_formula <- as.formula(pcp ~ poly(LONG, LAT, degree = poly_degree))

    # ajuste do modelo
    fit_lm <- lm(my_formula, data = pcp_temp)

    # estimando para os grids
    interpolation <- dplyr::mutate(
      grd_template_sl,
      Z = non_zero(predict(
        fit_lm,
        grd_template_sl
      ))
    )
    point_2_raster <- raster::rasterFromXYZ(
      interpolation,
      crs = "+proj=longlat +datum=WGS84 +no_defs"
    )

    raster_list[[i]] <- point_2_raster

    setTxtProgressBar(pb, i)
  }

  close(pb) # fim do bloco

  # renaming the objects list by the date
  names(raster_list) <- names_sans_ext

  # creating a raster brick
  raster::brick(raster_list)
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
