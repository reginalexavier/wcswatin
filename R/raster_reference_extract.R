#' Extract gridded values at station or reference points
#'
#' Extract values from a raster layer, stack or brick at reference point
#' locations and return a wide table with one column per point. This prepares
#' gridded or simulated data for point-based validation against station
#' observations.
#'
#' @param raster_file Raster object accepted by \code{\link{input_raster}}.
#' @param ref_points Reference point locations. This input can be a
#'   data.frame-like table with NAME, LAT and LON columns, a .txt or .csv file
#'   path, an sf object, a SpatVector object or a vector file path accepted by
#'   \code{\link{input_vector}}.
#' @param prefix_colname If not null, a character string used to prefix the
#'   station column names.
#' @param ... further arguments passed to \code{\link[terra]{extract}}. These
#'   arguments concern only extracting the data in the rasters.
#'
#' @details
#' This function does not calculate validation metrics. Instead, it prepares the
#' extracted raster values in a table shape that can be combined with observed
#' station data and then passed to validation tools such as
#' \code{hydroGOF::gof()}, \code{hydroGOF::ggof()} or any other function that
#' compares observed and simulated series.
#'
#' The returned table has one row per raster layer and one column per reference
#' point. Column names are taken from the NAME field in \code{ref_points},
#' optionally prefixed with \code{prefix_colname}. When combining this output
#' with observed data, make sure raster layers and observation rows represent
#' the same dates or time steps in the same order.
#'
#' Additional arguments passed through \code{...} are forwarded to
#' \code{\link[terra]{extract}}, allowing options such as \code{method},
#' \code{buffer} and \code{fun}.
#'
#' @return A data.frame with one row per raster layer and one column per
#'   reference point.
#' @export
#'
#' @examples
#' raster_layer <- terra::rast(
#'   nrows = 2,
#'   ncols = 2,
#'   vals = 1:4,
#'   crs = "EPSG:4326",
#'   extent = c(-1, 1, -1, 1)
#' )
#' raster_stack <- c(raster_layer, raster_layer + 10)
#'
#' stations <- data.frame(
#'   NAME = c("station_a", "station_b"),
#'   LAT = c(-0.5, 0.5),
#'   LON = c(-0.5, 0.5)
#' )
#'
#' simulated <- tbl_from_references(
#'   raster_file = raster_stack,
#'   ref_points = stations,
#'   prefix_colname = "sim"
#' )
#'
#' simulated
#'
#' # Example validation workflow:
#' # observed <- files_to_table(...)
#' # all_data <- cbind(observed, simulated)
#' # hydroGOF::gof(sim = all_data$sim_station_a, obs = all_data$station_a)
tbl_from_references <- function(
  raster_file,
  ref_points,
  prefix_colname = NULL,
  ...
) {
  raster_file <- input_raster(raster_file)
  ref_points <- reference_points_to_vect(ref_points)
  ref_points <- project_reference_points(ref_points, raster_file)

  dots <- list(...)
  dots$ID <- FALSE

  values_extracted <- do.call(
    terra::extract,
    c(list(x = raster_file, y = ref_points), dots)
  )

  df_extracted <- as.data.frame(t(values_extracted), row.names = FALSE)

  if (is.null(prefix_colname)) {
    colnames(df_extracted) <- ref_points$NAME
  } else {
    colnames(df_extracted) <- glue::glue(
      "{prefix_colname}_{ref_points$NAME}"
    )
  }

  df_extracted
}


#' Convert reference point inputs to SpatVector
#'
#' @noRd
#'
reference_points_to_vect <- function(ref_points) {
  if (inherits(ref_points, "SpatVector") || inherits(ref_points, "sf")) {
    ref_points <- input_vector(ref_points)
    validate_reference_points(ref_points)
    return(ref_points)
  }

  if (inherits(ref_points, "data.frame")) {
    ref_points <- reference_table_to_vect(input_table(ref_points))
    validate_reference_points(ref_points)
    return(ref_points)
  }

  if (is.character(ref_points) && length(ref_points) == 1) {
    ref_ext <- tools::file_ext(ref_points)

    if (ref_ext %in% c("csv", "txt")) {
      ref_points <- reference_table_to_vect(input_table(ref_points))
      validate_reference_points(ref_points)
      return(ref_points)
    }

    if (ref_ext %in% c("shp", "gpkg")) {
      ref_points <- input_vector(ref_points)
      validate_reference_points(ref_points)
      return(ref_points)
    }
  }

  stop(
    "The ref_points must be an object of class `sf`, `SpatVector`, ",
    "`data.frame` or a path to a `.csv`, `.txt`, `.shp` or `.gpkg` file."
  )
}


#' Convert a table with coordinates to SpatVector
#'
#' @noRd
#'
reference_table_to_vect <- function(ref_points) {
  validate_reference_table(ref_points)

  terra::vect(
    ref_points,
    geom = c("LON", "LAT"),
    crs = "EPSG:4326"
  )
}


#' Validate table columns required to build reference points
#'
#' @noRd
#'
validate_reference_table <- function(ref_points) {
  required_cols <- c("NAME", "LAT", "LON")
  missing_cols <- setdiff(required_cols, names(ref_points))

  if (length(missing_cols) > 0) {
    stop(
      "The argument 'ref_points' must contain the columns: ",
      paste(required_cols, collapse = ", "),
      "."
    )
  }
}


#' Validate reference point vector attributes and geometry
#'
#' @noRd
#'
validate_reference_points <- function(ref_points) {
  if (!"NAME" %in% names(ref_points)) {
    stop("The argument 'ref_points' must contain a 'NAME' column.")
  }

  if (!identical(terra::geomtype(ref_points), "points")) {
    stop("The argument 'ref_points' must contain point geometries.")
  }
}


#' Project reference points to the raster CRS when both CRS are known
#'
#' @noRd
#'
project_reference_points <- function(ref_points, raster_file) {
  raster_crs <- terra::crs(raster_file)
  points_crs <- terra::crs(ref_points)

  if (
    !is.na(raster_crs) &&
      nzchar(raster_crs) &&
      !is.na(points_crs) &&
      nzchar(points_crs) &&
      !terra::same.crs(ref_points, raster_file)
  ) {
    ref_points <- terra::project(ref_points, raster_crs)
  }

  ref_points
}
