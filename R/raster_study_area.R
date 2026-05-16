#' Study Area Records
#'
#' This function extracts the records position grid for the study area combining
#' with the DEM for every point
#'
#' @param raster_model One layer representing where the data wile be extracted
#' @param roi A shapefile delimiting the study area
#' @param dem An elevation raster for the study area
#'
#' @return A table
#' @export
#'
study_area_records <- function(raster_model, roi, dem) {
  raster_model <- input_raster(raster_model, lyrs = 1)
  roi <- input_vector(roi)
  dem <- input_raster(dem)
  # obtain cell numbers within the raster_model
  roi_cell <- raster_model |>
    terra::mask(
      roi |>
        terra::project(terra::crs(raster_model))
    ) |>
    terra::values(mat = FALSE)

  roi_cell <- which(!is.na(roi_cell))

  # obtain lat/long values corresponding to watershed cells
  cell_lon_lat <- terra::xyFromCell(raster_model, roi_cell)
  cell_row_col <- terra::rowColFromCell(raster_model, roi_cell)
  points_elevation <- terra::extract(
    x = dem,
    y = cell_lon_lat,
    method = "simple"
  )$elevation

  study_area_records <- data.table::data.table(
    cell_lon_lat,
    ID = roi_cell,
    cell_row_col,
    Elevation = points_elevation
  )

  names(study_area_records) <- c(
    "LON",
    "LAT",
    "ID",
    "ROW",
    "COL",
    "ELEVATION"
  )

  study_area_records
}
