# Tests for utils.R functions
# Following R package testing best practices

# Test setup
test_that("package loads correctly", {
  expect_true(require(wcswatin))
})

# Test files_to_table function
test_that("files_to_table works correctly", {
  # Setup test data
  temp_dir <- tempdir()
  test_file1 <- file.path(temp_dir, "test-file1.txt")
  test_file2 <- file.path(temp_dir, "test-file2.txt")

  # Create test files
  write.table(data.frame(value = c(1, 2, 3)), test_file1, row.names = FALSE)
  write.table(data.frame(value = c(4, 5, 6)), test_file2, row.names = FALSE)

  # Test the function
  result <- files_to_table(
    files_path = temp_dir,
    files_pattern = "test-file",
    start_date = "2020-01-01",
    end_date = "2020-01-03",
    interval = "day"
  )

  # Assertions
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 3) # date + 2 files
  expect_true("date" %in% names(result))

  # Clean up
  unlink(c(test_file1, test_file2))
})

test_that("files_to_table handles missing files gracefully", {
  temp_dir <- tempdir()

  # Test with non-existent pattern
  expect_error(
    files_to_table(
      files_path = temp_dir,
      files_pattern = "non-existent-pattern",
      start_date = "2020-01-01",
      end_date = "2020-01-03"
    ),
    class = "error"
  )
})

test_that("files_to_table handles NA values correctly", {
  temp_dir <- tempdir()
  test_file <- file.path(temp_dir, "test-na.txt")

  # Create test file with -99 values
  write.table(data.frame(value = c(1, -99, 3)), test_file, row.names = FALSE)

  result <- files_to_table(
    files_path = temp_dir,
    files_pattern = "test-na",
    start_date = "2020-01-01",
    end_date = "2020-01-03",
    na_value = -99
  )

  expect_true(is.na(result[2, 2]))

  # Clean up
  unlink(test_file)
})

# Test table_to_files function
test_that("table_to_files works correctly", {
  # Setup test data
  temp_dir <- tempdir()
  test_table <- data.frame(
    col1 = c(1, 2, 3),
    col2 = c(4, 5, 6)
  )

  # Test the function
  table_to_files(
    table = test_table,
    folder_path = temp_dir,
    first_date = "20200101",
    file_extension = "txt"
  )

  # Check if files were created
  expect_true(file.exists(file.path(temp_dir, "col1.txt")))
  expect_true(file.exists(file.path(temp_dir, "col2.txt")))

  # Check file contents
  col1_content <- read.table(file.path(temp_dir, "col1.txt"), header = TRUE)
  expect_equal(names(col1_content), "X20200101")
  expect_equal(nrow(col1_content), 3)

  # Clean up
  unlink(file.path(temp_dir, c("col1.txt", "col2.txt")))
})

# Test count_na function
test_that("count_na works correctly", {
  # Test data with NAs
  test_data <- data.frame(
    col1 = c(1, 2, NA),
    col2 = c(NA, NA, 3),
    col3 = c(1, 2, 3)
  )

  # Test count
  result_count <- count_na(test_data, percent = FALSE)
  expect_s3_class(result_count, "data.frame")
  expect_equal(nrow(result_count), 3)
  expect_equal(result_count$Prop_NA[1], 1) # col1 has 1 NA
  expect_equal(result_count$Prop_NA[2], 2) # col2 has 2 NAs
  expect_equal(result_count$Prop_NA[3], 0) # col3 has 0 NAs

  # Test percentage
  result_percent <- count_na(test_data, percent = TRUE)
  expect_equal(result_percent$Prop_NA[1], 100 / 3) # col1: 1/3 by 100
  expect_equal(result_percent$Prop_NA[2], 200 / 3) # col2: 2/3 by 100
  expect_equal(result_percent$Prop_NA[3], 0) # col3: 0/3 by 100
})

# Test var_names function
test_that("var_names requires valid input", {
  # This test mainly checks parameter validation
  # since creating actual NetCDF files is complex
  expect_error(var_names("non_existent_file.nc"))
})

# Test file_name function (internal)
test_that("file_name extracts correctly", {
  test_path <- "/path/to/file_tas_20200101.nc"
  # Note: This function might need to be exported for testing
  # or we test it indirectly through other functions
  skip("file_name is internal function")
})

# Test touch_dir function (internal)
test_that("touch_dir creates directories", {
  temp_test_dir <- file.path(tempdir(), "test_touch_dir")

  # Clean up first in case it exists
  if (dir.exists(temp_test_dir)) {
    unlink(temp_test_dir, recursive = TRUE)
  }

  # This would need the function to be exported or tested indirectly
  skip(
    "touch_dir is internal function - test indirectly through other functions"
  )
})

# Test clean_dir function (internal)
test_that("clean_dir removes directories", {
  skip(
    "clean_dir is internal function - test indirectly through other functions"
  )
})

# Test unit_converter function
test_that("unit_converter works correctly", {
  skip_on_cran()

  # Setup test data
  temp_dir_in <- file.path(tempdir(), "test_in")
  temp_dir_out <- file.path(tempdir(), "test_out")

  dir.create(temp_dir_in, showWarnings = FALSE, recursive = TRUE)
  dir.create(temp_dir_out, showWarnings = FALSE, recursive = TRUE)

  # Create test file with Kelvin temperatures
  test_file <- file.path(temp_dir_in, "temp_20200101.txt")
  kelvin_temps <- data.frame(temperature = c(273.15, 283.15, 293.15))
  write.table(kelvin_temps, test_file, row.names = FALSE, sep = ",", quote = FALSE)

  # Verify input file was created
  expect_true(file.exists(test_file))

  # Test conversion (Kelvin to Celsius)
  unit_converter(
    folder_in = temp_dir_in,
    folder_out = temp_dir_out,
    pattern = ".txt$",
    FUN = function(x) x - 273.15
  )

  # Check output directory has files
  output_files <- list.files(temp_dir_out, pattern = ".txt$", full.names = TRUE)
  expect_true(length(output_files) > 0)

  # Check specific output file
  output_file <- file.path(temp_dir_out, "temp_20200101.txt")

  # Debug: print available files if test fails
  if (!file.exists(output_file)) {
    message("Output file not found. Available files in output directory:")
    message(paste(list.files(temp_dir_out, full.names = TRUE), collapse = "\n"))
  }

  expect_true(file.exists(output_file))

  result <- read.table(output_file, header = TRUE, sep = ",")
  expect_equal(result$temperature[1], 0, tolerance = 0.01)
  expect_equal(result$temperature[2], 10, tolerance = 0.01)
  expect_equal(result$temperature[3], 20, tolerance = 0.01)

  # Clean up
  unlink(c(temp_dir_in, temp_dir_out), recursive = TRUE)
})

# Test summary_table function
test_that("summary_table works with test data", {
  # Setup test directory with sample files
  temp_dir <- tempdir()

  # Create multiple test files
  for (i in 1:3) {
    test_file <- file.path(temp_dir, paste0("test_", i, ".txt"))
    test_data <- data.frame(value = rnorm(10, mean = i * 10, sd = 2))
    write.table(test_data, test_file, row.names = FALSE)
  }

  # Test the function (without monthly grouping)
  result <- summary_table(
    var_folder = temp_dir,
    sample = 2,
    percent = FALSE,
    by_month = FALSE,
    pattern = "test_.*\\.txt$"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(ncol(result), 5) # min, max, mean, sd, n
  expect_true(all(c("min", "max", "mean", "sd", "n") %in% names(result)))

  # Clean up
  unlink(file.path(temp_dir, paste0("test_", 1:3, ".txt")))
})

# Test summary_plot function
test_that("summary_plot creates ggplot object", {
  # Setup test directory with sample files
  temp_dir <- tempdir()

  # Create test files
  for (i in 1:2) {
    test_file <- file.path(temp_dir, paste0("plot_test_", i, ".txt"))
    test_data <- data.frame(value = rnorm(365, mean = i * 5, sd = 1))
    write.table(test_data, test_file, row.names = FALSE)
  }

  # Test the function
  p <- summary_plot(
    var_folder = temp_dir,
    sample = 1,
    percent = FALSE,
    from = "2020-01-01",
    to = "2020-12-30",
    pattern = "plot_test_.*\\.txt$"
  )

  expect_s3_class(p, "ggplot")

  # Clean up
  unlink(file.path(temp_dir, paste0("plot_test_", 1:2, ".txt")))
})

# Test with real package data
test_that("point_to_daily works with package example data", {
  # Use the example data included in the package
  folder <- system.file("extdata/pcp_stations", package = "wcswatin")

  # Skip if no example data is available
  skip_if_not(dir.exists(folder), "Example data not available")

  result <- point_to_daily(
    my_folder = folder,
    start_date = "20170301",
    end_date = "20170331" # Small date range for testing
  )

  expect_type(result, "list")
  expect_gt(length(result), 0)
  expect_true(all(sapply(result, is.data.frame)))

  # Check that all tables have the expected structure
  first_table <- result[[1]]
  expect_true("NAME" %in% names(first_table))
  expect_true("pcp" %in% names(first_table))
})

test_that("save_daily_tbl saves files correctly", {
  # Create test data
  test_list <- list(
    "day_2020-01-01" = data.frame(
      ID = 1:3,
      NAME = paste0("station_", 1:3),
      value = c(1, 2, 3)
    ),
    "day_2020-01-02" = data.frame(
      ID = 1:3,
      NAME = paste0("station_", 1:3),
      value = c(4, 5, 6)
    )
  )

  temp_dir <- tempdir()

  save_daily_tbl(tbl_list = test_list, path = temp_dir)

  # Check files were created
  expect_true(file.exists(file.path(temp_dir, "day_2020-01-01.csv")))
  expect_true(file.exists(file.path(temp_dir, "day_2020-01-02.csv")))

  # Check file contents
  file1_content <- read.csv(file.path(temp_dir, "day_2020-01-01.csv"))
  expect_equal(nrow(file1_content), 3)
  expect_equal(file1_content$value, c(1, 2, 3))

  # Clean up
  unlink(file.path(temp_dir, c("day_2020-01-01.csv", "day_2020-01-02.csv")))
})

# Error handling tests
test_that("functions handle invalid inputs gracefully", {
  # Test files_to_table with invalid dates
  expect_error(
    files_to_table(
      files_path = tempdir(),
      files_pattern = "test",
      start_date = "invalid-date",
      end_date = "2020-01-01"
    )
  )

  # Test count_na with non-data.frame input
  expect_error(count_na("not a data frame"))

  # Test table_to_files with invalid table
  expect_error(
    table_to_files(
      table = "not a table",
      folder_path = tempdir(),
      first_date = "20200101"
    )
  )
})

# Performance tests (optional, for larger datasets)
test_that("functions perform reasonably with larger datasets", {
  skip_on_cran() # Skip on CRAN to avoid long test times

  # Create larger test dataset
  large_data <- data.frame(
    col1 = rnorm(10000),
    col2 = rnorm(10000),
    col3 = sample(c(NA, rnorm(8000)), 10000, replace = TRUE)
  )

  # Test count_na performance
  start_time <- Sys.time()
  result <- count_na(large_data)
  end_time <- Sys.time()

  expect_lt(as.numeric(end_time - start_time), 5) # Should complete in < 5 secs
  expect_s3_class(result, "data.frame")
})
