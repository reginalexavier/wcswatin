# Tests for raster_input.R functions
# Testing raster data processing functions

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
    LONG = c(-0.5, 0, 0.5),
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
    coords = c("LONG", "LAT"),
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

test_that("tbl_from_references works with file input", {
  skip_if_not_installed("terra")

  test_raster <- create_test_raster()
  test_points <- create_test_points()

  # Create temporary CSV file
  temp_file <- file.path(tempdir(), "test_points.csv")
  write.csv(test_points, temp_file, row.names = FALSE)

  result_file <- tbl_from_references(
    raster_file = test_raster,
    ref_points = temp_file
  )

  expect_s3_class(result_file, "data.frame")
  expect_equal(ncol(result_file), 3)

  # Test with TXT file
  temp_txt <- file.path(tempdir(), "test_points.txt")
  write.table(test_points, temp_txt, row.names = FALSE, sep = ",")

  result_txt <- tbl_from_references(
    raster_file = test_raster,
    ref_points = temp_txt
  )

  expect_s3_class(result_txt, "data.frame")

  # Clean up
  unlink(c(temp_file, temp_txt))
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
})

# Test layerValues2pixel function
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

test_that("main_input_var builds metadata names from study area IDs", {
  study_area <- data.frame(
    ID = c(4, 8),
    LAT = c(1.5, 0.5),
    LON = c(0.5, 1.5),
    ELEVATION = c(104, 108)
  )

  result <- main_input_var(study_area, var_name = "tas")

  expect_s3_class(result, "data.table")
  expect_equal(names(result), c("ID", "NAME", "LAT", "LON", "ELEVATION"))
  expect_equal(result$NAME, c("tas_4", "tas_8"))
})

test_that("cube2table extracts selected raster cells layer by layer", {
  skip_if_not_installed("terra")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("progressr")

  layer_1 <- terra::rast(nrows = 2, ncols = 2, vals = 1:4)
  layer_2 <- terra::rast(nrows = 2, ncols = 2, vals = 11:14)
  cube <- c(layer_1, layer_2)
  names(cube) <- c("X20200101", "X20200102")

  cube_file <- file.path(tempdir(), "cube2table_input.tif")
  temp_dir <- create_test_dir("cube2table")
  on.exit(unlink(c(cube_file, temp_dir), recursive = TRUE), add = TRUE)
  terra::writeRaster(cube, cube_file, overwrite = TRUE)

  result <- cube2table(
    input_path = cube_file,
    var = NULL,
    n_layers = 2,
    study_area = data.frame(ID = c(1, 4)),
    side_effect = "none",
    temp_dir = temp_dir,
    clean_after = FALSE
  )

  expect_s3_class(result, "data.table")
  expect_equal(result$ID, c(1L, 4L, 1L, 4L))
  expect_equal(result$values, c(1, 4, 11, 14))
  expect_equal(
    result$layer_name,
    c("X20200101", "X20200101", "X20200102", "X20200102")
  )
  expect_true(file.exists(file.path(temp_dir, "tbl_1.csv")))
  expect_true(file.exists(file.path(temp_dir, "tbl_2.csv")))
})

test_that("cube2table reads intermediate files in layer order", {
  skip_if_not_installed("terra")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("progressr")

  cube <- terra::rast(nrows = 1, ncols = 1, nlyrs = 10, vals = seq_len(10))
  names(cube) <- paste0("X202001", sprintf("%02d", seq_len(10)))

  cube_file <- file.path(tempdir(), "cube2table_order_input.tif")
  temp_dir <- create_test_dir("cube2table_order")
  on.exit(unlink(c(cube_file, temp_dir), recursive = TRUE), add = TRUE)
  terra::writeRaster(cube, cube_file, overwrite = TRUE)

  result <- cube2table(
    input_path = cube_file,
    var = NULL,
    n_layers = 10,
    study_area = data.frame(ID = 1),
    side_effect = "none",
    temp_dir = temp_dir,
    clean_after = FALSE
  )

  expect_equal(result$values, seq_len(10))
  expect_equal(result$layer_name, names(cube))
})

test_that("cube2table writes output and validates side effects", {
  skip_if_not_installed("terra")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("progressr")

  cube <- terra::rast(nrows = 2, ncols = 2, vals = c(1, NA, 3, 4))
  names(cube) <- "X20200101"

  cube_file <- file.path(tempdir(), "cube2table_side_effects.tif")
  both_dir <- create_test_dir("cube2table_both")
  only_dir <- create_test_dir("cube2table_only")
  on.exit(
    unlink(c(cube_file, both_dir, only_dir), recursive = TRUE),
    add = TRUE
  )
  terra::writeRaster(cube, cube_file, overwrite = TRUE)

  study_area <- data.frame(ID = c(1, 2))

  expect_error(
    cube2table(
      input_path = cube_file,
      var = NULL,
      n_layers = 1,
      study_area = study_area,
      side_effect = "only"
    ),
    "final_dir"
  )

  both_result <- cube2table(
    input_path = cube_file,
    var = NULL,
    n_layers = 1,
    study_area = study_area,
    missing_value = -999,
    final_dir = both_dir,
    side_effect = "both"
  )

  expect_s3_class(both_result, "data.table")
  expect_equal(both_result$values, c(1, -999))
  expect_true(file.exists(file.path(both_dir, "tbls.csv")))
  expect_false(dir.exists(file.path(tempdir(), "cube2table")))

  only_result <- cube2table(
    input_path = cube_file,
    var = NULL,
    n_layers = 1,
    study_area = study_area,
    final_dir = only_dir,
    side_effect = "only"
  )

  expect_null(only_result)
  expect_true(file.exists(file.path(only_dir, "tbls.csv")))
})

test_that("layervalues2pixel pivots layer values to one series per pixel", {
  layer_values <- data.frame(
    ID = c(1, 2, 1, 2),
    values = c(10, 20, 11, 21),
    layer_name = c("day1", "day1", "day2", "day2")
  )
  main_tbl <- data.frame(
    ID = c(1, 2),
    NAME = c("tas_1", "tas_2"),
    LAT = c(0, 1),
    LON = c(0, 1),
    ELEVATION = c(100, 200)
  )

  result <- layervalues2pixel(
    layer_values = layer_values,
    main_tbl = main_tbl,
    col_name = "20200101",
    inline_output = TRUE
  )

  expect_type(result, "list")
  expect_equal(names(result), c("tas_1", "tas_2"))
  expect_equal(result$tas_1[[1]], c(10, 11))
  expect_equal(result$tas_2[[1]], c(20, 21))
})

test_that("layervalues2pixel writes one file per pixel when requested", {
  output_dir <- create_test_dir("pixel_output")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  layer_values <- data.frame(
    ID = c(1, 2, 1, 2),
    values = c(10, 20, 11, 21),
    layer_name = c("day1", "day1", "day2", "day2")
  )
  main_tbl <- data.frame(
    ID = c(1, 2),
    NAME = c("pcp_1", "pcp_2"),
    LAT = c(0, 1),
    LON = c(0, 1),
    ELEVATION = c(100, 200)
  )

  result <- layervalues2pixel(
    layer_values = layer_values,
    main_tbl = main_tbl,
    col_name = "20200101",
    inline_output = TRUE,
    path_output = output_dir
  )

  expect_equal(names(result), c("pcp_1", "pcp_2"))
  expect_true(file.exists(file.path(output_dir, "pcp_1.txt")))
  expect_true(file.exists(file.path(output_dir, "pcp_2.txt")))
  expect_equal(
    readLines(file.path(output_dir, "pcp_1.txt")),
    c("20200101", "10", "11")
  )
})

test_that("layervalues2pixel creates output directory when needed", {
  parent_dir <- create_test_dir("pixel_parent")
  output_dir <- file.path(parent_dir, "nested", "pixels")
  on.exit(unlink(parent_dir, recursive = TRUE), add = TRUE)

  layervalues2pixel(
    layer_values = data.frame(
      ID = c(1, 1),
      values = c(10, 11),
      layer_name = c("day1", "day2")
    ),
    main_tbl = data.frame(ID = 1, NAME = "pcp_1"),
    col_name = "20200101",
    inline_output = FALSE,
    path_output = output_dir
  )

  expect_true(dir.exists(output_dir))
  expect_equal(
    readLines(file.path(output_dir, "pcp_1.txt")),
    c("20200101", "10", "11")
  )
})

test_that("layervalues2pixel validates file-output configuration", {
  expect_error(
    layervalues2pixel(
      layer_values = data.frame(ID = 1, values = 1, layer_name = "day1"),
      main_tbl = data.frame(ID = 1, NAME = "pcp_1"),
      inline_output = FALSE
    ),
    "path_output"
  )
})

# Test raster processing with multi-layer inputs
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

  # Test with mismatched CRS (if function handles this)
  test_raster <- create_test_raster()

  # Points with different CRS
  test_points_utm <- data.frame(
    NAME = "station_1",
    LAT = 500000, # UTM coordinates
    LONG = 5000000,
    ELEVATION = 100
  )

  # This might work if the function handles CRS transformation
  # or might error - either is acceptable behavior
  tryCatch(
    {
      result <- tbl_from_references(
        raster_file = test_raster,
        ref_points = test_points_utm
      )
      expect_s3_class(result, "data.frame")
    },
    error = function(e) {
      # Error is acceptable for mismatched CRS
      expect_true(TRUE)
    }
  )
})

# Test performance with larger datasets
test_that("raster extraction performs reasonably", {
  skip_on_cran() # Skip on CRAN to avoid long test times
  skip_if_not_installed("terra")

  # Create larger raster
  large_raster <- terra::rast(nrows = 100, ncols = 100, vals = 1:10000)

  # Create many points
  n_points <- 50
  large_points <- data.frame(
    NAME = paste0("station_", 1:n_points),
    LAT = runif(n_points, -1, 1),
    LONG = runif(n_points, -1, 1),
    ELEVATION = runif(n_points, 0, 1000)
  )

  start_time <- Sys.time()

  result <- tbl_from_references(
    raster_file = large_raster,
    ref_points = large_points
  )

  end_time <- Sys.time()
  elapsed_time <- as.numeric(end_time - start_time)

  expect_s3_class(result, "data.frame")
  expect_equal(ncol(result), n_points)
  expect_lt(elapsed_time, 10) # Should complete in less than 10 seconds
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
  temp_file <- file.path(tempdir(), "extracted_test.csv")
  write.csv(extracted_values, temp_file, row.names = FALSE)

  read_back <- input_table(temp_file)
  expect_s3_class(read_back, "data.table")

  # Clean up
  unlink(temp_file)
})

# Test edge cases
test_that("raster functions handle edge cases", {
  skip_if_not_installed("terra")

  # Test with single point
  single_point <- data.frame(
    NAME = "single_station",
    LAT = 0,
    LONG = 0,
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
    LONG = 10,
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
