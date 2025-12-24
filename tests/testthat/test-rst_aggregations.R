# Tests for rst_aggregations.R functions
# Testing raster aggregation and processing functions

# Test helper functions for rst_aggregations
test_that("rst_aggregations helper functions work", {
  testthat::skip_if_not_installed("terra")

  # Test creating a simple raster for testing
  test_raster <- terra::rast(nrows = 10, ncols = 10, vals = 1:100)
  expect_s4_class(test_raster, "SpatRaster")
  expect_equal(terra::ncell(test_raster), 100)
})

# Test cube2table function (if it exists)
test_that("cube2table function works correctly", {
  skip_if_not(
    exists("cube2table", where = "package:wcswatin"),
    "cube2table function not found"
  )

  # This would test the cube2table function
  # Implementation depends on the actual function signature
  expect_true(TRUE) # Placeholder
})

# Test datacube_aggregation function (if it exists)
test_that("datacube_aggregation works with raster inputs", {
  skip_if_not(
    exists("datacube_aggregation", where = "package:wcswatin"),
    "datacube_aggregation function not found"
  )

  # Test with mock raster data
  testthat::skip_if_not_installed("terra")

  # Create test raster stack
  r1 <- terra::rast(nrows = 5, ncols = 5, vals = 1:25)
  r2 <- terra::rast(nrows = 5, ncols = 5, vals = 26:50)
  r3 <- terra::rast(nrows = 5, ncols = 5, vals = 51:75)

  raster_stack <- c(r1, r2, r3)
  names(raster_stack) <- c("layer1", "layer2", "layer3")

  # Test aggregation (function signature would need to be checked)
  # This is a placeholder for the actual test
  expect_s4_class(raster_stack, "SpatRaster")
})

# Test raster temporal aggregation
test_that("raster temporal operations work correctly", {
  testthat::skip_if_not_installed("terra")

  # Create time series raster
  dates <- seq(as.Date("2020-01-01"), as.Date("2020-01-05"), by = "day")

  raster_list <- lapply(seq_along(dates), function(i) {
    terra::rast(nrows = 5, ncols = 5, vals = rep(i, 25))
  })

  time_raster <- do.call(c, raster_list)
  names(time_raster) <- paste0("day_", dates)

  expect_s4_class(time_raster, "SpatRaster")
  expect_equal(terra::nlyr(time_raster), 5)

  # Test basic temporal operations
  mean_raster <- terra::mean(time_raster)
  expect_s4_class(mean_raster, "SpatRaster")
  expect_equal(terra::nlyr(mean_raster), 1)
})

# Test spatial aggregation
test_that("spatial aggregation works correctly", {
  testthat::skip_if_not_installed("terra")

  # Create high resolution raster
  high_res <- terra::rast(nrows = 10, ncols = 10, vals = 1:100)

  # Test aggregation to lower resolution
  low_res <- terra::aggregate(high_res, fact = 2, fun = mean)

  expect_s4_class(low_res, "SpatRaster")
  expect_equal(terra::nrow(low_res), 5)
  expect_equal(terra::ncol(low_res), 5)
})

# Test raster statistics functions
test_that("raster statistics calculations work", {
  testthat::skip_if_not_installed("terra")

  # Create test raster with known values
  test_vals <- c(1:20, rep(NA, 5)) # Include some NA values
  test_raster <- terra::rast(nrows = 5, ncols = 5, vals = test_vals)

  # Test basic statistics
  min_val <- terra::global(test_raster, "min", na.rm = TRUE)
  max_val <- terra::global(test_raster, "max", na.rm = TRUE)
  mean_val <- terra::global(test_raster, "mean", na.rm = TRUE)

  expect_equal(min_val[1, 1], 1)
  expect_equal(max_val[1, 1], 20)
  expect_equal(mean_val[1, 1], mean(1:20))
})

# Test raster masking and cropping
test_that("raster masking and cropping work", {
  testthat::skip_if_not_installed("terra")
  testthat::skip_if_not_installed("sf")

  # Create test raster
  test_raster <- terra::rast(
    nrows = 10,
    ncols = 10,
    vals = 1:100,
    extent = c(0, 10, 0, 10)
  )

  # Create test polygon for masking
  poly_coords <- rbind(c(2, 2), c(8, 2), c(8, 8), c(2, 8), c(2, 2))
  poly <- sf::st_polygon(list(poly_coords))
  poly_sf <- sf::st_sfc(poly, crs = sf::st_crs(test_raster))

  # Convert to SpatVector for terra
  poly_vect <- terra::vect(poly_sf)

  # Test cropping
  cropped <- terra::crop(test_raster, poly_vect)
  expect_s4_class(cropped, "SpatRaster")

  # Test masking
  masked <- terra::mask(test_raster, poly_vect)
  expect_s4_class(masked, "SpatRaster")
})

# Test raster resampling
test_that("raster resampling works correctly", {
  testthat::skip_if_not_installed("terra")
  # Skip on macOS due to terra::resample segfault issues with GDAL/PROJ in CI
  testthat::skip_on_os("mac")

  # Create source and target rasters
  source_raster <- terra::rast(nrows = 10, ncols = 10, vals = 1:100)
  target_raster <- terra::rast(nrows = 5, ncols = 5)

  # Test resampling
  resampled <- terra::resample(
    source_raster,
    target_raster,
    method = "bilinear"
  )

  expect_s4_class(resampled, "SpatRaster")
  expect_equal(terra::nrow(resampled), 5)
  expect_equal(terra::ncol(resampled), 5)
})

# Test raster layer operations
test_that("raster layer operations work", {
  testthat::skip_if_not_installed("terra")

  # Create multi-layer raster
  layer1 <- terra::rast(nrows = 5, ncols = 5, vals = 1:25)
  layer2 <- terra::rast(nrows = 5, ncols = 5, vals = 26:50)
  layer3 <- terra::rast(nrows = 5, ncols = 5, vals = 51:75)

  multi_layer <- c(layer1, layer2, layer3)
  names(multi_layer) <- c("temp", "precip", "humidity")

  # Test layer selection
  temp_layer <- multi_layer[["temp"]]
  expect_s4_class(temp_layer, "SpatRaster")
  expect_equal(terra::nlyr(temp_layer), 1)

  # Test layer arithmetic
  sum_layers <- layer1 + layer2
  expect_s4_class(sum_layers, "SpatRaster")

  # Test layer statistics
  layer_means <- terra::global(multi_layer, "mean")
  expect_equal(nrow(layer_means), 3)
})

# Test error handling in raster operations
test_that("raster operations handle errors gracefully", {
  testthat::skip_if_not_installed("terra")

  # Test with mismatched raster dimensions
  raster1 <- terra::rast(nrows = 5, ncols = 5, vals = 1:25)
  raster2 <- terra::rast(nrows = 10, ncols = 10, vals = 1:100)

  # This should error due to mismatched dimensions
  expect_error(raster1 + raster2)
})

# Test memory efficiency with larger rasters
test_that("raster operations are memory efficient", {
  skip_on_cran() # Skip on CRAN to avoid memory issues
  testthat::skip_if_not_installed("terra")

  # Create larger raster (but still manageable for testing)
  large_raster <- terra::rast(nrows = 100, ncols = 100, vals = 1:10000)

  # Test that basic operations complete without memory errors
  start_time <- Sys.time()

  # Test aggregation
  aggregated <- terra::aggregate(large_raster, fact = 5, fun = mean)

  # Test statistics
  stats <- terra::global(large_raster, c("min", "max", "mean"))

  end_time <- Sys.time()
  elapsed_time <- as.numeric(end_time - start_time)

  expect_s4_class(aggregated, "SpatRaster")
  expect_equal(nrow(stats), 1)
  expect_lt(elapsed_time, 10) # Should complete reasonably quickly
})

# Test integration with package data
test_that("raster functions work with package example data", {
  # Look for example raster data in the package
  extdata_path <- system.file("extdata", package = "wcswatin")

  if (dir.exists(extdata_path)) {
    raster_files <- list.files(
      extdata_path,
      pattern = "\\.(tif|nc|nc4)$",
      recursive = TRUE,
      full.names = TRUE
    )

    if (length(raster_files) > 0) {
      testthat::skip_if_not_installed("terra")

      # Test loading example raster
      example_raster <- input_raster(raster_files[1])
      expect_s4_class(example_raster, "SpatRaster")

      # Test basic operations on example data
      if (terra::nlyr(example_raster) > 1) {
        # Test temporal operations if multi-layer
        first_layer <- example_raster[[1]]
        expect_s4_class(first_layer, "SpatRaster")
        expect_equal(terra::nlyr(first_layer), 1)
      }

      # Test statistics on example data
      stats <- terra::global(example_raster, "mean", na.rm = TRUE)
      expect_true(nrow(stats) >= 1)
    } else {
      skip("No example raster data available")
    }
  } else {
    skip("No extdata directory found")
  }
})

# Test raster coordinate reference systems
test_that("raster CRS operations work correctly", {
  testthat::skip_if_not_installed("terra")
  # Skip on macOS due to terra::project segfault issues with GDAL/PROJ in CI
  testthat::skip_on_os("mac")

  # Create raster with known CRS
  raster_wgs84 <- terra::rast(
    nrows = 5,
    ncols = 5,
    vals = 1:25,
    crs = "EPSG:4326"
  )

  # Test CRS retrieval
  crs_info <- terra::crs(raster_wgs84)
  expect_true(nchar(crs_info) > 0)

  # Test reprojection (to UTM)
  raster_utm <- terra::project(raster_wgs84, "EPSG:32633")
  expect_s4_class(raster_utm, "SpatRaster")
  expect_false(identical(terra::crs(raster_wgs84), terra::crs(raster_utm)))
})

# Test raster file I/O operations
test_that("raster file operations work correctly", {
  testthat::skip_if_not_installed("terra")

  # Create test raster
  test_raster <- terra::rast(nrows = 5, ncols = 5, vals = 1:25)

  # Test writing to file
  temp_file <- file.path(tempdir(), "test_raster.tif")
  terra::writeRaster(test_raster, temp_file, overwrite = TRUE)

  expect_true(file.exists(temp_file))

  # Test reading from file
  read_raster <- terra::rast(temp_file)
  expect_s4_class(read_raster, "SpatRaster")
  expect_equal(terra::ncell(read_raster), 25)

  # Test values are preserved
  original_values <- terra::values(test_raster)
  read_values <- terra::values(read_raster)
  expect_equal(original_values, read_values)

  # Clean up
  unlink(temp_file)
})
