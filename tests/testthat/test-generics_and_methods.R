# Tests for generics_and_methods.R
# Testing S4 methods and generics

# Test input_raster generic and methods
test_that("input_raster works with character input", {
  # Test with non-existent file (should error appropriately)
  expect_error(
    input_raster("non_existent_file.nc"),
    "File does not exist"
  )

  # Test with unsupported file extension
  expect_error(
    input_raster("file.xyz"),
    "File does not exist"
  )
})

test_that("input_raster accepts supported file extensions", {
  # Create temporary files with supported extensions
  temp_dir <- tempdir()

  # Test file extension validation (without actually creating the files)
  # since creating valid raster files is complex
  nc_file <- file.path(temp_dir, "test.nc")
  tif_file <- file.path(temp_dir, "test.tif")

  # criar os arquivos temporários
  terra::writeCDF(
    terra::rast(nrows = 10, ncols = 10, vals = 1:100),
    nc_file,
    overwrite = TRUE
  )
  terra::writeRaster(
    terra::rast(nrows = 10, ncols = 10, vals = 1:100),
    tif_file,
    overwrite = TRUE
  )

  # check
  expect_s4_class(input_raster(nc_file), "SpatRaster")
  expect_s4_class(input_raster(tif_file), "SpatRaster")

  # Test unsupported extension
  bad_file <- file.path(temp_dir, "test.bad")
  file.create(bad_file)
  expect_error(input_raster(bad_file), "The file extension is not supported")
})

test_that("input_raster works with SpatRaster input", {
  testthat::skip_if_not_installed("terra")

  # Create a simple SpatRaster for testing
  r <- terra::rast(nrows = 10, ncols = 10, vals = 1:100)

  result <- input_raster(r)
  expect_s4_class(result, "SpatRaster")
  expect_equal(result, r)
})

test_that("input_raster works with RasterLayer input", {
  skip_if_not_installed("raster")
  skip_if_not_installed("terra")

  # Create a simple RasterLayer for testing
  r <- raster::raster(nrows = 10, ncols = 10, vals = 1:100)

  result <- input_raster(r)
  expect_s4_class(result, "SpatRaster")
})

test_that("input_raster works with RasterBrick input", {
  skip_if_not_installed("raster")
  skip_if_not_installed("terra")

  # Create a simple RasterBrick for testing
  r1 <- raster::raster(nrows = 10, ncols = 10, vals = 1:100)
  r2 <- raster::raster(nrows = 10, ncols = 10, vals = 101:200)
  rb <- raster::brick(r1, r2)

  result <- input_raster(rb)
  expect_s4_class(result, "SpatRaster")
})

test_that("input_raster works with RasterStack input", {
  skip_if_not_installed("raster")
  skip_if_not_installed("terra")

  # Create a simple RasterStack for testing
  r1 <- raster::raster(nrows = 10, ncols = 10, vals = 1:100)
  r2 <- raster::raster(nrows = 10, ncols = 10, vals = 101:200)
  rs <- raster::stack(r1, r2)

  result <- input_raster(rs)
  expect_s4_class(result, "SpatRaster")
})

# Test input_vector generic and methods
test_that("input_vector works with character input", {
  temp_dir <- tempdir()
  # Test with non-existent file
  expect_error(
    input_vector("non_existent_file.shp"),
    "File does not exist"
  )

  # Test with unsupported file extension
  bad_file <- file.path(temp_dir, "test.bad")
  expect_error(
    input_vector(bad_file),
    "file extension is not supported"
  )
})

test_that("input_vector accepts supported file extensions", {
  temp_dir <- tempdir()

  # Test file extension validation
  shp_file <- file.path(temp_dir, "test.shp")
  gpkg_file <- file.path(temp_dir, "test.gpkg")

  # These will fail because files don't exist, but we can test the extension
  # check
  expect_error(input_vector(shp_file), "File does not exist")
  expect_error(input_vector(gpkg_file), "File does not exist")

  # Test unsupported extension
  bad_file <- file.path(temp_dir, "test.bad")
  expect_error(input_vector(bad_file), "file extension is not supported")
})

test_that("input_vector works with SpatVector input", {
  skip_if_not_installed("terra")

  # Create a simple SpatVector for testing
  x <- c(-110, -90, -80)
  y <- c(40, 50, 45)
  v <- terra::vect(cbind(x, y), crs = "epsg:4326")

  result <- input_vector(v)
  expect_s4_class(result, "SpatVector")
  expect_equal(result, v)
})

test_that("input_vector works with sf input", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")

  # Create a simple sf object for testing
  pts <- data.frame(
    x = c(-110, -90, -80),
    y = c(40, 50, 45),
    id = 1:3
  )
  sf_obj <- sf::st_as_sf(pts, coords = c("x", "y"), crs = 4326)

  result <- input_vector(sf_obj)
  expect_s4_class(result, "SpatVector")
})

# Test input_table generic and methods
test_that("input_table works with character input", {
  # Create a test CSV file
  temp_dir <- tempdir()
  test_file <- file.path(temp_dir, "test.csv")
  write.csv(data.frame(a = 1:3, b = 4:6), test_file, row.names = FALSE)

  result <- input_table(test_file)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 2)

  # Test with txt file
  test_file_txt <- file.path(temp_dir, "test.txt")
  write.table(data.frame(a = 1:3, b = 4:6), test_file_txt, row.names = FALSE)

  result_txt <- input_table(test_file_txt)
  expect_s3_class(result_txt, "data.table")

  # Test with unsupported extension
  bad_file <- file.path(temp_dir, "test.bad")
  writeLines("some text", bad_file)
  expect_error(input_table(bad_file), "file extension is not supported")

  # Clean up
  unlink(c(test_file, test_file_txt, bad_file))
})

test_that("input_table works with data.table input", {
  skip_if_not_installed("data.table")

  dt <- data.table::data.table(a = 1:3, b = 4:6)
  result <- input_table(dt)

  expect_s3_class(result, "data.table")
  expect_equal(result, dt)
})

test_that("input_table works with data.frame input", {
  skip_if_not_installed("data.table")

  df <- data.frame(a = 1:3, b = 4:6)
  result <- input_table(df)

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 2)
})

test_that("input_table works with tibble input", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("data.table")

  tbl <- dplyr::tibble(a = 1:3, b = 4:6)
  result <- input_table(tbl)

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 2)
})

# Test that generics are properly defined
test_that("generics are properly defined", {
  expect_true(methods::isGeneric("input_raster"))
  expect_true(methods::isGeneric("input_vector"))
  expect_true(methods::isGeneric("input_table"))
})

# Test method dispatch
test_that("method dispatch works correctly", {
  # Test that appropriate methods exist
  expect_true(methods::existsMethod("input_raster", "character"))
  expect_true(methods::existsMethod("input_raster", "SpatRaster"))

  expect_true(methods::existsMethod("input_vector", "character"))
  expect_true(methods::existsMethod("input_vector", "SpatVector"))

  expect_true(methods::existsMethod("input_table", "character"))
  expect_true(methods::existsMethod("input_table", "data.table"))
  expect_true(methods::existsMethod("input_table", "data.frame"))
})

# Integration tests
test_that("methods work together in workflow", {
  skip_if_not_installed("terra")
  skip_if_not_installed("data.table")

  # Create test data
  temp_dir <- tempdir()
  test_file <- file.path(temp_dir, "integration_test.csv")
  write.csv(data.frame(x = 1:5, y = 6:10), test_file, row.names = FALSE)

  # Test workflow
  table_result <- input_table(test_file)
  expect_s3_class(table_result, "data.table")

  # Test with raster workflow (create simple raster)
  r <- terra::rast(nrows = 10, ncols = 10, vals = 1:100)
  raster_result <- input_raster(r)
  expect_s4_class(raster_result, "SpatRaster")

  # Clean up
  unlink(test_file)
})

# Error handling and edge cases
test_that("methods handle edge cases appropriately", {
  # Test with empty data.frame
  empty_df <- data.frame()
  result <- input_table(empty_df)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0)

  # Test with single column data.frame
  single_col_df <- data.frame(a = 1:3)
  result <- input_table(single_col_df)
  expect_s3_class(result, "data.table")
  expect_equal(ncol(result), 1)
})
