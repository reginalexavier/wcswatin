# Tests for raster_study_area.R

test_that("study_area_records extracts raster cell metadata inside an ROI", {
  skip_if_not_installed("terra")

  raster_model <- terra::rast(
    nrows = 3,
    ncols = 3,
    xmin = 0,
    xmax = 3,
    ymin = 0,
    ymax = 3,
    vals = 1:9,
    crs = "EPSG:4326"
  )
  dem <- terra::rast(raster_model, vals = 101:109)
  names(dem) <- "elevation"
  roi <- terra::vect(
    "POLYGON((0 0, 2 0, 2 2, 0 2, 0 0))",
    crs = "EPSG:4326"
  )

  result <- study_area_records(raster_model, roi, dem)

  expect_s3_class(result, "data.table")
  expect_equal(names(result), c("LON", "LAT", "ID", "ROW", "COL", "ELEVATION"))
  expect_equal(result$ID, c(4L, 5L, 7L, 8L))
  expect_equal(result$ELEVATION, c(104L, 105L, 107L, 108L))
})
