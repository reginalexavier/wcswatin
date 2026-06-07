#' Extract gridded values at station or reference points
#'
#' Extract values from a raster layer, stack or brick at reference point
#' locations and return a wide table with one column per point. This prepares
#' gridded or simulated data for point-based validation against station
#' observations.
#'
#' @param raster_file Raster object accepted by \code{\link[raster]{extract}}.
#' @param ref_points A table or sf object containing the field station reference
#'   points. This input can be a character string informing the address of a
#'   .txt or .csv file, a data.frame or an sf object. The table must have NAME,
#'   LAT and LON fields/columns.
#' @param prefix_colname If not null, a character string used to prefix the
#'   station column names.
#' @param ... further arguments from \code{\link[raster]{extract}}. These
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
#' \code{\link[raster]{extract}}, allowing options such as \code{method},
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
  if ("sf" %in% class(ref_points)) {
    ref_points <- ref_points
  } else if ("data.frame" %in% class(ref_points)) {
    ref_points <- sf::st_as_sf(
      ref_points,
      coords = c("LON", "LAT"),
      crs = "+proj=longlat +datum=WGS84 +no_defs"
    )
  } else if (
    "character" %in%
      class(ref_points) &&
      any(stringr::str_ends(ref_points, c(".txt", ".csv")))
  ) {
    tbl_ref <- data.table::fread(ref_points)
    ref_points <- sf::st_as_sf(
      tbl_ref,
      coords = c("LON", "LAT"),
      crs = "+proj=longlat +datum=WGS84 +no_defs"
    )
  } else {
    stop(
      "The ref_points must be an object of class `sf`, `data.frame` ",
      "or a string character of the path of a file with ",
      "extension `.csv` or `.txt`!"
    )
  }
  # extração dos  valores nos rasters
  values_extracted <- raster::extract(
    raster_file,
    ref_points,
    ...
  )

  df_extracted <- as.data.frame(t(values_extracted[, -1]), row.names = FALSE)

  if (is.null(prefix_colname)) {
    colnames(df_extracted) <- ref_points$NAME
  } else {
    colnames(df_extracted) <- glue::glue(
      "{prefix_colname}_{ref_points$NAME}"
    )
  }

  df_extracted
}
