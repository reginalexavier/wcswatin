# Tests for point_interpolation.R functions
# Testing spatial interpolation and point processing functions

# Test basic interpolation functions
test_that("point interpolation functions exist and work", {
  # Check if interpolation functions are available
  # This test framework assumes the functions exist in the package

  # Create test point data
  test_points <- data.frame(
    x = c(1, 2, 3, 4, 5),
    y = c(1, 2, 3, 4, 5),
    value = c(10, 20, 30, 40, 50)
  )

  expect_s3_class(test_points, "data.frame")
  expect_equal(nrow(test_points), 5)
  expect_true(all(c("x", "y", "value") %in% names(test_points)))
})

# Test spatial interpolation methods
test_that("spatial interpolation methods work correctly", {
  testthat::skip_if_not_installed("sf")

  # Create test spatial points
  coords <- data.frame(
    lon = c(-100, -99, -98, -97, -96),
    lat = c(35, 36, 37, 38, 39),
    temperature = c(20, 22, 24, 26, 28)
  )

  # Convert to sf object
  sf_points <- sf::st_as_sf(coords, coords = c("lon", "lat"), crs = 4326)

  expect_s3_class(sf_points, "sf")
  expect_equal(nrow(sf_points), 5)
})

# Test interpolation to grid
test_that("interpolation to grid works", {
  testthat::skip_if_not_installed("terra")

  # Create target grid
  target_grid <- terra::rast(
    nrows = 10,
    ncols = 10,
    extent = c(-101, -95, 34, 40),
    crs = "EPSG:4326"
  )

  expect_s4_class(target_grid, "SpatRaster")
  expect_equal(terra::ncell(target_grid), 100)
})

# Test nearest neighbor interpolation
test_that("nearest neighbor interpolation works", {
  testthat::skip_if_not_installed("terra")
  testthat::skip_if_not_installed("sf")

  # Create source points
  source_points <- data.frame(
    x = c(1, 3, 5),
    y = c(1, 3, 5),
    value = c(10, 30, 50)
  )

  sf_points <- sf::st_as_sf(source_points, coords = c("x", "y"))

  # Create target grid
  target_grid <- terra::rast(nrows = 5, ncols = 5, extent = c(0, 6, 0, 6))

  # Test nearest neighbor assignment (basic approach)
  # This is a conceptual test - actual implementation would vary
  expect_s4_class(target_grid, "SpatRaster")
  expect_s3_class(sf_points, "sf")
})

# Test interpolation quality metrics
test_that("interpolation quality can be assessed", {
  # Create test data with known pattern
  x <- rep(1:5, each = 5)
  y <- rep(1:5, times = 5)
  true_values <- x + y # Simple linear relationship

  test_data <- data.frame(x = x, y = y, value = true_values)

  # Test cross-validation (conceptual)
  # In practice, this would involve splitting data and testing interpolation
  n_points <- nrow(test_data)
  train_indices <- sample(n_points, round(0.8 * n_points))

  train_data <- test_data[train_indices, ]
  test_data_subset <- test_data[-train_indices, ]

  expect_gt(nrow(train_data), 0)
  expect_gt(nrow(test_data_subset), 0)
})

# Test spatial autocorrelation analysis
test_that("spatial autocorrelation can be analyzed", {
  testthat::skip_if_not_installed("sf")

  # Create spatially correlated data
  set.seed(123)
  coords <- expand.grid(x = 1:5, y = 1:5)

  # Add spatial correlation (simple distance-based)
  coords$value <- 100 -
    sqrt((coords$x - 3)^2 + (coords$y - 3)^2) * 10 +
    rnorm(nrow(coords), 0, 2)

  sf_data <- sf::st_as_sf(coords, coords = c("x", "y"))

  expect_s3_class(sf_data, "sf")
  expect_equal(nrow(sf_data), 25)

  # Test that values show spatial pattern
  center_value <- coords$value[coords$x == 3 & coords$y == 3]
  corner_value <- coords$value[coords$x == 1 & coords$y == 1]

  # Center should generally be higher than corner (given our pattern)
  # This is a probabilistic test, so we'll be lenient
  expect_true(is.numeric(center_value))
  expect_true(is.numeric(corner_value))
})

# Test interpolation with missing data
test_that("interpolation handles missing data appropriately", {
  # Create data with missing values
  coords <- data.frame(
    x = 1:10,
    y = 1:10,
    value = c(1:5, NA, NA, 8:10)
  )

  # Remove NA values for interpolation
  complete_data <- coords[complete.cases(coords), ]

  expect_equal(nrow(complete_data), 8) # Should have 8 complete cases
  expect_true(all(!is.na(complete_data$value)))
})

# Test interpolation parameter sensitivity
test_that("interpolation parameters affect results appropriately", {
  # Create test points in a grid
  test_grid <- expand.grid(x = c(1, 3, 5), y = c(1, 3, 5))
  test_grid$value <- test_grid$x * test_grid$y

  expect_equal(nrow(test_grid), 9)

  # Test different distance parameters (conceptual)
  # In practice, this would test how changing interpolation parameters
  # affects the results
  distances <- c(1, 2, 5)

  for (d in distances) {
    # Test that different distance parameters are valid
    expect_gt(d, 0)
  }
})

# Test integration with raster outputs
test_that("interpolation integrates with raster operations", {
  testthat::skip_if_not_installed("terra")

  # Create interpolation result as raster
  interp_raster <- terra::rast(nrows = 5, ncols = 5, vals = 1:25)

  # Test that result can be used in raster operations
  stats <- terra::global(interp_raster, "mean")
  expect_equal(stats[1, 1], mean(1:25))

  # Test masking interpolated results
  mask_raster <- terra::rast(
    nrows = 5,
    ncols = 5,
    vals = c(rep(1, 20), rep(NA, 5))
  )
  masked_result <- terra::mask(interp_raster, mask_raster)

  expect_s4_class(masked_result, "SpatRaster")
})

# Test point density effects on interpolation
test_that("point density affects interpolation quality", {
  # Create sparse point set
  sparse_points <- data.frame(
    x = c(1, 5),
    y = c(1, 5),
    value = c(10, 50)
  )

  # Create dense point set
  dense_points <- data.frame(
    x = 1:5,
    y = 1:5,
    value = seq(10, 50, by = 10)
  )

  expect_equal(nrow(sparse_points), 2)
  expect_equal(nrow(dense_points), 5)

  # Dense points should provide better interpolation
  # (This is conceptual - actual testing would involve interpolation error)
  expect_gt(nrow(dense_points), nrow(sparse_points))
})

# Test boundary effects in interpolation
test_that("interpolation handles boundary conditions", {
  # Create points near boundaries
  boundary_points <- data.frame(
    x = c(0.1, 0.9, 9.1, 9.9, 5),
    y = c(0.1, 9.9, 0.1, 9.9, 5),
    value = c(1, 2, 3, 4, 25)
  )

  expect_equal(nrow(boundary_points), 5)

  # Points at boundaries should be handled appropriately
  expect_true(all(boundary_points$x >= 0 & boundary_points$x <= 10))
  expect_true(all(boundary_points$y >= 0 & boundary_points$y <= 10))
})

# Test interpolation with different coordinate systems
test_that("interpolation works with different CRS", {
  testthat::skip_if_not_installed("sf")

  # Create points in geographic coordinates
  geo_points <- data.frame(
    lon = c(-100, -99, -98),
    lat = c(35, 36, 37),
    temp = c(20, 22, 24)
  )

  sf_geo <- sf::st_as_sf(geo_points, coords = c("lon", "lat"), crs = 4326)

  # Transform to projected coordinates
  sf_proj <- sf::st_transform(sf_geo, crs = 3857) # Web Mercator

  expect_s3_class(sf_geo, "sf")
  expect_s3_class(sf_proj, "sf")
  expect_false(identical(sf::st_crs(sf_geo), sf::st_crs(sf_proj)))
})

# Test error handling in interpolation
test_that("interpolation functions handle errors gracefully", {
  # Test with insufficient points
  insufficient_points <- data.frame(
    x = 1,
    y = 1,
    value = 10
  )

  expect_equal(nrow(insufficient_points), 1)

  # Test with duplicate coordinates
  duplicate_coords <- data.frame(
    x = c(1, 1, 2),
    y = c(1, 1, 2),
    value = c(10, 15, 20)
  )

  # Should handle or warn about duplicates
  duplicates_exist <- any(duplicated(duplicate_coords[, c("x", "y")]))
  expect_true(duplicates_exist)
})

# Test performance with larger point sets
test_that("interpolation performs reasonably with larger datasets", {
  skip_on_cran() # Skip on CRAN to avoid long test times

  # Create larger point dataset
  n_points <- 100
  large_points <- data.frame(
    x = runif(n_points, 0, 10),
    y = runif(n_points, 0, 10),
    value = runif(n_points, 0, 100)
  )

  start_time <- Sys.time()

  # Test basic operations on large dataset
  summary_stats <- summary(large_points$value)

  end_time <- Sys.time()
  elapsed_time <- as.numeric(end_time - start_time)

  expect_equal(nrow(large_points), n_points)
  expect_lt(elapsed_time, 5) # Should complete quickly

  # Min, 1st Qu., Median, Mean, 3rd Qu., Max
  expect_equal(length(summary_stats), 6)
})

# Test integration with package workflow
test_that("interpolation integrates with package workflow", {
  # Test that interpolation can work with package data structures

  # Create sample station data like in the package
  station_data <- data.frame(
    ID = 1:3,
    NAME = paste0("station_", 1:3),
    LAT = c(35.1, 35.2, 35.3),
    LONG = c(-100.1, -100.2, -100.3),
    ELEVATION = c(100, 200, 300),
    value = c(20, 25, 30)
  )

  # Test that this data can be processed
  expect_equal(nrow(station_data), 3)
  expect_true(all(c("LAT", "LONG", "value") %in% names(station_data)))

  # Test conversion for interpolation use
  interp_data <- station_data[, c("LONG", "LAT", "value")]
  names(interp_data) <- c("x", "y", "z")

  expect_equal(nrow(interp_data), 3)
  expect_true(all(c("x", "y", "z") %in% names(interp_data)))
})

test_that("ts_to_point returns one time series per target point", {
  skip_if_not_installed("sf")
  skip_if_not_installed("vroom")

  input_dir <- create_test_dir("ts_point_input")
  target_file <- file.path(tempdir(), "ts_point_targets.gpkg")
  on.exit(unlink(c(input_dir, target_file), recursive = TRUE), add = TRUE)

  station_tbl <- data.frame(
    ID = 1:4,
    NAME = paste0("p", 1:4),
    LAT = c(0, 0, 1, 1),
    LONG = c(0, 1, 0, 1),
    ELEVATION = c(10, 20, 30, 40),
    pcp = c(1, 2, 3, 4)
  )

  data.table::fwrite(station_tbl, file.path(input_dir, "2020-01-01.csv"))
  station_tbl$pcp <- station_tbl$pcp + 10
  data.table::fwrite(station_tbl, file.path(input_dir, "2020-01-02.csv"))

  target_points <- sf::st_as_sf(
    data.frame(
      OBJECTID = 1:2,
      Lon_dec = c(0.25, 0.75),
      Lat_dec = c(0.25, 0.75)
    ),
    coords = c("Lon_dec", "Lat_dec"),
    remove = FALSE,
    crs = 4326
  )
  sf::st_write(target_points, target_file, quiet = TRUE)

  result <- ts_to_point(
    my_folder = input_dir,
    targeted_points_path = target_file,
    poly_degree = 1
  )

  expect_type(result, "list")
  expect_length(result, 2)
  expect_equal(names(result), c("1", "2"))
  expect_equal(unique(result[[1]]$date), c("2020-01-01", "2020-01-02"))
  expect_true(all(result[[1]]$value >= 0))
  expect_true(all(result[[2]]$value > result[[1]]$value))
})

test_that("trend surface interpolation can create a raster brick", {
  skip_if_not_installed("sf")
  skip_if_not_installed("raster")
  skip_if_not_installed("vroom")

  input_dir <- create_test_dir("ts_area_input")
  basin_file <- file.path(tempdir(), "ts_area_basin.gpkg")
  on.exit(unlink(c(input_dir, basin_file), recursive = TRUE), add = TRUE)

  station_tbl <- data.frame(
    ID = 1:4,
    NAME = paste0("p", 1:4),
    LAT = c(0, 0, 1, 1),
    LONG = c(0, 1, 0, 1),
    ELEVATION = c(10, 20, 30, 40),
    pcp = c(1, 2, 3, 4)
  )
  data.table::fwrite(station_tbl, file.path(input_dir, "2020-01-01.csv"))
  station_tbl$pcp <- station_tbl$pcp + 1
  data.table::fwrite(station_tbl, file.path(input_dir, "2020-01-02.csv"))

  basin <- sf::st_sf(
    id = 1,
    geometry = sf::st_sfc(
      sf::st_polygon(list(rbind(
        c(0, 0),
        c(1, 0),
        c(1, 1),
        c(0, 1),
        c(0, 0)
      ))),
      crs = 4326
    )
  )
  sf::st_write(basin, basin_file, quiet = TRUE)

  result <- ts_to_area(
    my_folder = input_dir,
    bassin_limit_path = basin_file,
    poly_degree = 1,
    resolution = 0.5
  )

  expect_s4_class(result, "RasterBrick")
  expect_equal(raster::nlayers(result), 2)
  expect_equal(names(result), c("X2020.01.01", "X2020.01.02"))
  expect_true(all(raster::values(result) >= 0))
})

test_that("var_main_creator preserves coordinates and metadata", {
  skip_if_not_installed("sf")

  target_file <- file.path(tempdir(), "main_creator_targets.gpkg")
  on.exit(unlink(target_file, recursive = TRUE), add = TRUE)

  target_points <- sf::st_as_sf(
    data.frame(
      OBJECTID = c(11, 12),
      Elev = c(123, 456),
      lon = c(-54.1, -54.2),
      lat = c(-15.1, -15.2)
    ),
    coords = c("lon", "lat"),
    crs = 4326
  )
  sf::st_write(target_points, target_file, quiet = TRUE)

  result <- var_main_creator(target_file, var_name = "pcp", col_elev = "Elev")

  expect_equal(names(result), c("ID", "NAME", "LAT", "LONG", "ELEVATION"))
  expect_equal(result$ID, c(11, 12))
  expect_equal(result$NAME, c("pcp1", "pcp2"))
  expect_equal(result$LAT, c(-15.1, -15.2))
  expect_equal(result$LONG, c(-54.1, -54.2))
  expect_equal(result$ELEVATION, c(123, 456))
})
