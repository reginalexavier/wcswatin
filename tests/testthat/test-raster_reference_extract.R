# Tests for raster_reference_extract.R

# Setup helper function to create test raster
create_test_raster <- function() {
  testthat::skip_if_not_installed("terra")
  terra::rast(
    nrows = 10,
    ncols = 10,
    vals = 1:100,
    crs = "EPSG:4326",
    extent = c(-1, 1, -1, 1)
  )
}

# Setup helper function to create test points
create_test_points <- function() {
  data.frame(
    NAME = paste0("station_", 1:3),
    LAT = c(-0.5, 0, 0.5),
    LON = c(-0.5, 0, 0.5),
    ELEVATION = c(100, 200, 300)
  )
}

# Test tbl_from_references function

test_that("tbl_from_references works with different input types", {
  testthat::skip_if_not_installed("terra")
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("raster")

  # Create test raster and points
  test_raster <- create_test_raster()
  test_points <- create_test_points()

  # Test with data.frame input
  result_df <- tbl_from_references(
    raster_file = test_raster,
    ref_points = test_points
  )

  expect_s3_class(result_df, "data.frame")
  expect_equal(ncol(result_df), 3) # 3 stations
  expect_equal(nrow(result_df), 1) # 1 layer in raster
  expect_true(all(paste0("station_", 1:3) %in% names(result_df)))
})

test_that("tbl_from_references works with sf input", {
  testthat::skip_if_not_installed("terra")
  testthat::skip_if_not_installed("sf")

  test_raster <- create_test_raster()
  test_points <- create_test_points()

  # Convert to sf object
  sf_points <- sf::st_as_sf(
    test_points,
    coords = c("LON", "LAT"),
    crs = "EPSG:4326"
  )

  result_sf <- tbl_from_references(
    raster_file = test_raster,
    ref_points = sf_points
  )

  expect_s3_class(result_sf, "data.frame")
  expect_equal(ncol(result_sf), 3)
  expect_true(all(paste0("station_", 1:3) %in% names(result_sf)))
})

test_that("tbl_from_references works with SpatVector input", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")

  test_raster <- create_test_raster()
  test_points <- create_test_points()

  spat_points <- test_points |>
    sf::st_as_sf(coords = c("LON", "LAT"), crs = "EPSG:4326") |>
    terra::vect()

  result_spat <- tbl_from_references(
    raster_file = test_raster,
    ref_points = spat_points
  )

  expect_s3_class(result_spat, "data.frame")
  expect_equal(ncol(result_spat), 3)
  expect_true(all(paste0("station_", 1:3) %in% names(result_spat)))
})

test_that("tbl_from_references works with file input", {
  skip_if_not_installed("terra")

  test_raster <- create_test_raster()
  test_points <- create_test_points()

  # Create temporary CSV file
  temp_file <- local_test_file("test_points", ".csv")
  write.csv(test_points, temp_file, row.names = FALSE)

  result_file <- tbl_from_references(
    raster_file = test_raster,
    ref_points = temp_file
  )

  expect_s3_class(result_file, "data.frame")
  expect_equal(ncol(result_file), 3)

  # Test with TXT file
  temp_txt <- local_test_file("test_points", ".txt")
  write.table(test_points, temp_txt, row.names = FALSE, sep = ",")

  result_txt <- tbl_from_references(
    raster_file = test_raster,
    ref_points = temp_txt
  )

  expect_s3_class(result_txt, "data.frame")
})

test_that("tbl_from_references handles prefix correctly", {
  skip_if_not_installed("terra")

  test_raster <- create_test_raster()
  test_points <- create_test_points()

  result_with_prefix <- tbl_from_references(
    raster_file = test_raster,
    ref_points = test_points,
    prefix_colname = "precip"
  )

  expect_s3_class(result_with_prefix, "data.frame")
  expected_names <- paste0("precip_station_", 1:3)
  expect_true(all(expected_names %in% names(result_with_prefix)))
})

test_that("tbl_from_references validates input", {
  skip_if_not_installed("terra")

  test_raster <- create_test_raster()

  # Test with invalid ref_points type
  expect_error(
    tbl_from_references(
      raster_file = test_raster,
      ref_points = "invalid_input"
    ),
    "ref_points must be an object of class"
  )

  # Test with non-existent file
  expect_error(
    tbl_from_references(
      raster_file = test_raster,
      ref_points = "/non/existent/file.csv"
    )
  )

  expect_error(
    tbl_from_references(
      raster_file = test_raster,
      ref_points = data.frame(NAME = "station_1", LAT = 0)
    ),
    "must contain the columns"
  )

  expect_error(
    tbl_from_references(
      raster_file = test_raster,
      ref_points = data.frame(LAT = 0, LON = 0)
    ),
    "must contain the columns"
  )
})

# Test layerValues2pixel function

test_that("tbl_from_references works with multi-layer rasters", {
  skip_if_not_installed("terra")

  # Create multi-layer raster
  r1 <- terra::rast(nrows = 10, ncols = 10, vals = 1:100)
  r2 <- terra::rast(nrows = 10, ncols = 10, vals = 101:200)
  multi_raster <- c(r1, r2)

  test_points <- create_test_points()

  result <- tbl_from_references(
    raster_file = multi_raster,
    ref_points = test_points
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2) # 2 layers
  expect_equal(ncol(result), 3) # 3 stations
})

test_that("tbl_from_references works with legacy raster objects", {
  skip_if_not_installed("raster")
  skip_if_not_installed("terra")

  test_points <- create_test_points()
  raster_layer <- raster::raster(
    nrows = 10,
    ncols = 10,
    vals = 1:100,
    crs = "+proj=longlat +datum=WGS84 +no_defs",
    xmn = -1,
    xmx = 1,
    ymn = -1,
    ymx = 1
  )
  raster_stack <- raster::stack(raster_layer, raster_layer + 100)

  result_layer <- tbl_from_references(
    raster_file = raster_layer,
    ref_points = test_points
  )
  result_stack <- tbl_from_references(
    raster_file = raster_stack,
    ref_points = test_points
  )

  expect_s3_class(result_layer, "data.frame")
  expect_equal(nrow(result_layer), 1)
  expect_equal(ncol(result_layer), 3)

  expect_s3_class(result_stack, "data.frame")
  expect_equal(nrow(result_stack), 2)
  expect_equal(ncol(result_stack), 3)
  expect_equal(names(result_stack), test_points$NAME)
})

# Test raster extraction with different methods

test_that("tbl_from_references works with extraction parameters", {
  skip_if_not_installed("terra")
  skip_if_not_installed("raster")

  test_raster <- create_test_raster()
  test_points <- create_test_points()

  # Test with bilinear interpolation
  result_bilinear <- tbl_from_references(
    raster_file = test_raster,
    ref_points = test_points,
    method = "bilinear"
  )

  expect_s3_class(result_bilinear, "data.frame")

  # Test with buffer extraction
  result_buffer <- tbl_from_references(
    raster_file = test_raster,
    ref_points = test_points,
    buffer = 1000,
    fun = mean
  )

  expect_s3_class(result_buffer, "data.frame")
})

# Test with real package data

test_that("raster functions work with package example data", {
  # Check if package has example raster data
  extdata_path <- system.file("extdata", package = "wcswatin")

  if (dir.exists(extdata_path)) {
    # Look for raster files
    raster_files <- list.files(
      extdata_path,
      pattern = "\\.(tif|nc|nc4)$",
      recursive = TRUE,
      full.names = TRUE
    )

    if (length(raster_files) > 0) {
      skip_if_not_installed("terra")

      # Test with first available raster file
      test_raster <- input_raster(raster_files[1])

      # Use example points from the package
      points_file <- system.file(
        "extdata/pcp_stations/pcp.txt",
        package = "wcswatin"
      )

      if (file.exists(points_file)) {
        result <- tbl_from_references(
          raster_file = test_raster,
          ref_points = points_file
        )

        expect_s3_class(result, "data.frame")
        expect_gt(ncol(result), 0)
      }
    } else {
      skip("No example raster data available")
    }
  } else {
    skip("No extdata directory found")
  }
})

# Test error handling

test_that("raster functions handle errors gracefully", {
  skip_if_not_installed("terra")

  test_points <- create_test_points()

  # Test with invalid raster
  expect_error(
    tbl_from_references(
      raster_file = "non_existent_raster.tif",
      ref_points = test_points
    )
  )
})

# Test integration with other package functions

test_that("raster functions integrate with other package components", {
  skip_if_not_installed("terra")

  test_raster <- create_test_raster()
  test_points <- create_test_points()

  # Extract values
  extracted_values <- tbl_from_references(
    raster_file = test_raster,
    ref_points = test_points
  )

  # Test that extracted data can be used with other functions
  # Add date column to simulate time series
  extracted_with_date <- cbind(
    date = as.Date("2020-01-01"),
    extracted_values
  )

  # Test with count_na function
  na_summary <- count_na(extracted_with_date)
  expect_s3_class(na_summary, "data.frame")

  # Test writing to file and reading back
  temp_file <- local_test_file("extracted_test", ".csv")
  write.csv(extracted_values, temp_file, row.names = FALSE)

  read_back <- input_table(temp_file)
  expect_s3_class(read_back, "data.table")
})

# Test edge cases

test_that("raster functions handle edge cases", {
  skip_if_not_installed("terra")

  # Test with single point
  single_point <- data.frame(
    NAME = "single_station",
    LAT = 0,
    LON = 0,
    ELEVATION = 100
  )

  test_raster <- create_test_raster()

  result_single <- tbl_from_references(
    raster_file = test_raster,
    ref_points = single_point
  )

  expect_s3_class(result_single, "data.frame")
  expect_equal(ncol(result_single), 1)

  # Test with points outside raster extent
  outside_points <- data.frame(
    NAME = "outside_station",
    LAT = 10, # Outside the raster extent
    LON = 10,
    ELEVATION = 100
  )

  result_outside <- tbl_from_references(
    raster_file = test_raster,
    ref_points = outside_points
  )

  expect_s3_class(result_outside, "data.frame")
  # Values should be NA for points outside extent
  expect_true(is.na(result_outside[1, 1]))
})
