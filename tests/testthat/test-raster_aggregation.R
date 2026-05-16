# Tests for raster_aggregation.R

test_that("datacube_aggregation aggregates raster layers by date", {
  skip_if_not_installed("terra")

  cube <- c(
    terra::rast(nrows = 2, ncols = 2, vals = 1:4),
    terra::rast(nrows = 2, ncols = 2, vals = 10:13),
    terra::rast(nrows = 2, ncols = 2, vals = 100:103)
  )
  names(cube) <- c("time=0", "time=3600", "time=90000")

  output_file <- local_test_file("daily_cube", ".tif")

  result <- datacube_aggregation(
    input_path = cube,
    output_filename = output_file,
    fun = sum
  )

  expect_s4_class(result, "SpatRaster")
  expect_equal(terra::nlyr(result), 2)
  expect_equal(as.vector(terra::values(result[[1]])), c(11, 13, 15, 17))
  expect_equal(as.vector(terra::values(result[[2]])), c(100, 101, 102, 103))
})
