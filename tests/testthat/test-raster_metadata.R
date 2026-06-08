# Tests for raster_metadata.R

test_that("var_names requires valid input", {
  # This test mainly checks parameter validation
  # since creating actual NetCDF files is complex
  expect_error(var_names("non_existent_file.nc"))
})

test_that("var_names returns only raster variables", {
  skip_if_not_installed("ncdf4")

  nc_file <- system.file(
    "extdata/nc_data/hourly_multi_2days_2025.nc",
    package = "wcswatin"
  )
  skip_if(nc_file == "", "Example multi-variable NetCDF data not available")

  expect_setequal(
    var_names(nc_file),
    c("d2m", "t2m", "ssrd", "u10", "v10", "tp")
  )
})

test_that("raster_info validates input", {
  expect_error(raster_info(1), "character vector")
  expect_error(raster_info("non_existent_file.nc"), "File does not exist")
})

test_that("raster_info summarizes generic raster files", {
  skip_if_not_installed("terra")

  raster_file <- local_test_file("metadata_raster", ".tif")
  raster_obj <- terra::rast(
    nrows = 2,
    ncols = 3,
    nlyrs = 2,
    vals = seq_len(12),
    crs = "EPSG:4326",
    extent = c(-55, -54, -16, -15)
  )
  terra::writeRaster(raster_obj, raster_file)

  info <- raster_info(raster_file)

  expect_s3_class(info, "data.table")
  expect_equal(info$file, basename(raster_file))
  expect_equal(info$variable, tools::file_path_sans_ext(basename(raster_file)))
  expect_equal(info$n_layers, 2L)
  expect_equal(info$n_rows, 2)
  expect_equal(info$n_cols, 3)
  expect_match(info$crs, "EPSG:4326", fixed = TRUE)
  expect_false(info$has_time)
})

test_that("raster_info summarizes daily NetCDF metadata", {
  skip_if_not_installed("terra")
  skip_if_not_installed("ncdf4")

  nc_file <- system.file(
    "extdata/nc_data/daily_2m_temperature_daily_maximum_2025.nc",
    package = "wcswatin"
  )
  skip_if(nc_file == "", "Example NetCDF data not available")

  info <- raster_info(nc_file)

  expect_s3_class(info, "data.table")
  expect_equal(nrow(info), 1)
  expect_equal(info$file, basename(nc_file))
  expect_equal(info$variable, "t2m")
  expect_equal(info$unit, "K")
  expect_equal(info$n_layers, 5L)
  expect_equal(info$n_rows, 19)
  expect_equal(info$n_cols, 28)
  expect_true(info$has_time)
  expect_match(info$crs, "OGC:CRS84", fixed = TRUE)
  expect_equal(info$time_start, "2025-10-01")
  expect_equal(info$time_end, "2025-10-05")
  expect_equal(info$time_step, "days")
  expect_equal(info$time_resolution, "1 days")
})

test_that("raster_info summarizes multi-variable NetCDF metadata", {
  skip_if_not_installed("terra")
  skip_if_not_installed("ncdf4")

  nc_file <- system.file(
    "extdata/nc_data/hourly_multi_2days_2025.nc",
    package = "wcswatin"
  )
  skip_if(nc_file == "", "Example multi-variable NetCDF data not available")

  info <- raster_info(nc_file)

  expect_s3_class(info, "data.table")
  expect_true(all(info$file == basename(nc_file)))
  expect_setequal(
    info$variable,
    c("d2m", "t2m", "ssrd", "u10", "v10", "tp")
  )
  expect_true(all(info$n_layers == 48L))
  expect_true(all(info$time_start == "2025-10-01"))
  expect_true(all(info$time_end == "2025-10-02 23:00:00"))
  expect_true(all(info$time_step == "hours"))
  expect_true(all(info$time_resolution == "1 hours"))
  expect_equal(info[variable == "tp"]$unit, "m")
})
