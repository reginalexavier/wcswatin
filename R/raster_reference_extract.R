#' Create a table with the values extracted from the reference points
#'
#' This function prepares the data table with extracting values in the same
#' geographical locations as the field stations. This helps to validate data
#' downloaded from online platforms with data collected from field stations.
#'
#' @param raster_file Raster* object.
#' @param ref_points A table or sf object containing the field station reference
#'   points. This input can be a character string informing the address of a
#'   .txt or .csv file, a data.frame or an sf object. The table must have NAME,
#'   LAT and LON fields/columns.
#' @param prefix_colname If not null, a string character to be used to prefix
#'   the original column names.
#' @param ... further arguments from \code{\link[raster]{extract}}. These
#'   arguments concern only extracting the data in the rasters.
#'
#' @return A table.
#' @export
#'
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
      coords = c("LONG", "LAT"),
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
      coords = c("LONG", "LAT"), # TODO: rename LONG to LON
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
