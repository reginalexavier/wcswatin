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

test_that("datacube_aggregation selects daily layers by value hour", {
  skip_if_not_installed("terra")

  cube <- c(
    terra::rast(nrows = 1, ncols = 2, vals = c(1, 2)),
    terra::rast(nrows = 1, ncols = 2, vals = c(10, 20)),
    terra::rast(nrows = 1, ncols = 2, vals = c(100, 200)),
    terra::rast(nrows = 1, ncols = 2, vals = c(1000, 2000)),
    terra::rast(nrows = 1, ncols = 2, vals = c(10000, 20000))
  )
  names(cube) <- c(
    "time=0",
    "time=3600",
    "time=86400",
    "time=90000",
    "time=172800"
  )

  output_file <- local_test_file("daily_value_hour", ".tif")

  result <- datacube_aggregation(
    input_path = cube,
    output_filename = output_file,
    mode = "value_at_hour",
    value_hour = 0,
    date_shift_days = -1,
    drop_first_layer = TRUE
  )

  expect_s4_class(result, "SpatRaster")
  expect_equal(terra::nlyr(result), 2)
  expect_equal(as.vector(terra::values(result[[1]])), c(100, 200))
  expect_equal(as.vector(terra::values(result[[2]])), c(10000, 20000))
  expect_equal(
    as.Date(terra::time(result)),
    as.Date(c("1970-01-01", "1970-01-02"))
  )
  expect_equal(names(result), c("d_1970.01.01", "d_1970.01.02"))
})

test_that("datacube_aggregation validates value hour mode inputs", {
  skip_if_not_installed("terra")

  cube <- terra::rast(nrows = 1, ncols = 1, vals = 1)
  names(cube) <- "time=3600"

  expect_error(
    datacube_aggregation(
      input_path = cube,
      output_filename = local_test_file("bad_hour", ".tif"),
      mode = "value_at_hour",
      value_hour = 24
    ),
    "value_hour"
  )

  expect_error(
    datacube_aggregation(
      input_path = cube,
      output_filename = local_test_file("missing_hour", ".tif"),
      mode = "value_at_hour",
      value_hour = 0
    ),
    "No raster layers were found"
  )

  expect_error(
    datacube_aggregation(
      input_path = cube,
      output_filename = local_test_file("bad_shift", ".tif"),
      mode = "value_at_hour",
      date_shift_days = 0.5
    ),
    "date_shift_days"
  )
})
