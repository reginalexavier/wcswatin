# Tests for raster_cube_tables.R

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

test_that("cube2table extracts selected raster cells layer by layer", {
  skip_if_not_installed("terra")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("progressr")

  layer_1 <- terra::rast(nrows = 2, ncols = 2, vals = 1:4)
  layer_2 <- terra::rast(nrows = 2, ncols = 2, vals = 11:14)
  cube <- c(layer_1, layer_2)
  names(cube) <- c("X20200101", "X20200102")

  cube_file <- local_test_file("cube2table_input", ".tif")
  temp_dir <- local_test_dir("cube2table")
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

  cube_file <- local_test_file("cube2table_order_input", ".tif")
  temp_dir <- local_test_dir("cube2table_order")
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

  cube_file <- local_test_file("cube2table_side_effects", ".tif")
  both_dir <- local_test_dir("cube2table_both")
  only_dir <- local_test_dir("cube2table_only")
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
  output_dir <- local_test_dir("pixel_output")

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
  parent_dir <- local_test_dir("pixel_parent")
  output_dir <- file.path(parent_dir, "nested", "pixels")

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
