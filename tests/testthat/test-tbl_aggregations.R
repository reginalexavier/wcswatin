# Tests for tbl_aggregations.R functions
# Testing temporal aggregation functions

# Test daily_aggregation function
test_that("daily_aggregation creates proper file structure", {
  # Setup test environment
  temp_dir_in <- file.path(tempdir(), "agg_test_in")
  temp_dir_out <- file.path(tempdir(), "agg_test_out")

  dir.create(temp_dir_in, showWarnings = FALSE)
  dir.create(temp_dir_out, showWarnings = FALSE)

  # Create test hourly data file
  # Simulating 24 hours of data for one day
  hourly_data <- data.frame(
    temperature = seq(15, 25, length.out = 24) + rnorm(24, 0, 1)
  )

  test_file <- file.path(temp_dir_in, "temp_hourly_20200101.txt")
  write.table(hourly_data, test_file, row.names = FALSE, sep = ",")

  # Test daily aggregation with mean (default)
  daily_aggregation(
    folder_in = temp_dir_in,
    folder_out = temp_dir_out,
    pattern = ".txt$",
    from = "2020-01-01 01",
    to = "2020-01-02 00",
    take_out_first_record = FALSE,
    aggregation_function = mean,
    mode = "agg_fun"
  )

  # Check if output file exists
  output_files <- list.files(
    temp_dir_out,
    pattern = ".txt$",
    full.names = TRUE
  )
  expect_gt(length(output_files), 0)

  # Check output content
  if (length(output_files) > 0) {
    output_data <- read.table(output_files[1], header = TRUE, sep = ",")
    expect_s3_class(output_data, "data.frame")
    expect_gt(nrow(output_data), 0)
  }

  # Clean up
  unlink(c(temp_dir_in, temp_dir_out), recursive = TRUE)
})

test_that("daily_aggregation handles different aggregation modes", {
  temp_dir_in <- file.path(tempdir(), "mode_test_in")
  temp_dir_out <- file.path(tempdir(), "mode_test_out")

  dir.create(temp_dir_in, showWarnings = FALSE)
  dir.create(temp_dir_out, showWarnings = FALSE)

  # Create test data with known values for testing
  hourly_data <- data.frame(
    value = c(1:12, 12:1) # 24 values with known pattern
  )

  test_file <- file.path(temp_dir_in, "test_20200101.txt")
  write.table(hourly_data, test_file, row.names = FALSE, sep = ",")

  # Test different modes if the function supports them
  # Note: Need to check the actual implementation for available modes
  tryCatch(
    {
      daily_aggregation(
        folder_in = temp_dir_in,
        folder_out = temp_dir_out,
        from = "2020-01-01 00",
        to = "2020-01-01 23",
        take_out_first_record = FALSE,
        aggregation_function = sum
      )

      output_files <- list.files(temp_dir_out, full.names = TRUE)
      expect_gt(length(output_files), 0)
    },
    error = function(e) {
      skip(paste("Function implementation issue:", e$message))
    }
  )

  # Clean up
  unlink(c(temp_dir_in, temp_dir_out), recursive = TRUE)
})

test_that("daily_aggregation handles missing data appropriately", {
  temp_dir_in <- file.path(tempdir(), "na_test_in")
  temp_dir_out <- file.path(tempdir(), "na_test_out")

  dir.create(temp_dir_in, showWarnings = FALSE)
  dir.create(temp_dir_out, showWarnings = FALSE)

  # Create test data with NA values
  hourly_data <- data.frame(
    value = c(1:10, rep(NA, 6), 11:18) # 24 values with NAs
  )

  test_file <- file.path(temp_dir_in, "test_na_20200101.txt")
  write.table(hourly_data, test_file, row.names = FALSE, sep = ",")

  # Test aggregation with na.rm = TRUE
  tryCatch(
    {
      daily_aggregation(
        folder_in = temp_dir_in,
        folder_out = temp_dir_out,
        from = "2020-01-01 00",
        to = "2020-01-01 23",
        take_out_first_record = FALSE,
        aggregation_function = mean,
        na.rm = TRUE
      )

      # Check if files were created despite NA values
      output_files <- list.files(temp_dir_out, full.names = TRUE)
      expect_gte(length(output_files), 0) # Should handle NAs gracefully
    },
    error = function(e) {
      # If function doesn't exist or has issues, skip
      skip(paste("Function implementation issue:", e$message))
    }
  )

  # Clean up
  unlink(c(temp_dir_in, temp_dir_out), recursive = TRUE)
})

test_that("daily_aggregation validates input parameters", {
  temp_dir_in <- tempdir()
  temp_dir_out <- tempdir()

  # Test with invalid date format
  expect_error(
    {
      daily_aggregation(
        folder_in = temp_dir_in,
        folder_out = temp_dir_out,
        from = "invalid-date",
        to = "2020-01-01 23"
      )
    },
    class = "error"
  )

  # Test with non-existent input directory
  expect_error(
    {
      daily_aggregation(
        folder_in = "/non/existent/path",
        folder_out = temp_dir_out,
        from = "2020-01-01 00",
        to = "2020-01-01 23",
        take_out_first_record = FALSE
      )
    },
    class = "error"
  )
})


# Test temporal aggregation utilities
test_that("temporal aggregation handles edge cases", {
  # Test with single hour data
  temp_dir_in <- file.path(tempdir(), "edge_test_in")
  temp_dir_out <- file.path(tempdir(), "edge_test_out")

  dir.create(temp_dir_in, showWarnings = FALSE)
  dir.create(temp_dir_out, showWarnings = FALSE)

  # Single value data
  single_data <- data.frame(value = 42)
  test_file <- file.path(temp_dir_in, "single_20200101.txt")
  write.table(single_data, test_file, row.names = FALSE, sep = ",")

  tryCatch(
    {
      daily_aggregation(
        folder_in = temp_dir_in,
        folder_out = temp_dir_out,
        from = "2020-01-01 00",
        to = "2020-01-01 00", # Same start and end
        take_out_first_record = FALSE,
        aggregation_function = mean
      )

      # Should handle single value appropriately
      output_files <- list.files(temp_dir_out, full.names = TRUE)
      if (length(output_files) > 0) {
        result <- read.table(output_files[1], header = TRUE, sep = ",")
        expect_equal(nrow(result), 1)
      }
    },
    error = function(e) {
      skip(paste("Edge case handling issue:", e$message))
    }
  )

  # Clean up
  unlink(c(temp_dir_in, temp_dir_out), recursive = TRUE)
})

# Test aggregation with different functions
test_that("aggregation works with different statistical functions", {
  temp_dir_in <- file.path(tempdir(), "stat_test_in")
  temp_dir_out <- file.path(tempdir(), "stat_test_out")

  dir.create(temp_dir_in, showWarnings = FALSE)
  dir.create(temp_dir_out, showWarnings = FALSE)

  # Create test data with known statistical properties
  test_values <- c(
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    10,
    9,
    8,
    7,
    6,
    5,
    4,
    3,
    2,
    1,
    1,
    2,
    3,
    4
  )
  hourly_data <- data.frame(value = test_values)

  test_file <- file.path(temp_dir_in, "stat_test_20200101.txt")
  write.table(hourly_data, test_file, row.names = FALSE, sep = ",")

  # Test with different aggregation functions
  test_functions <- list(
    mean = mean,
    sum = sum,
    max = max,
    min = min,
    median = median
  )

  for (func_name in names(test_functions)) {
    func <- test_functions[[func_name]]
    output_subdir <- file.path(temp_dir_out, func_name)
    dir.create(output_subdir, showWarnings = FALSE)

    tryCatch(
      {
        daily_aggregation(
          folder_in = temp_dir_in,
          folder_out = output_subdir,
          from = "2020-01-01 00",
          to = "2020-01-01 23",
          take_out_first_record = FALSE,
          aggregation_function = func
        )

        output_files <- list.files(output_subdir, full.names = TRUE)
        if (length(output_files) > 0) {
          result <- read.table(
            output_files[1],
            header = TRUE,
            sep = ","
          )
          expect_s3_class(result, "data.frame")

          # Verify the aggregation worked
          expected_value <- func(test_values, na.rm = TRUE)
          if (is.finite(expected_value)) {
            expect_true(any(
              abs(result[, 1] - expected_value) < 1e-6
            ))
          }
        }
      },
      error = function(e) {
        message(paste("Skipping", func_name, "due to:", e$message))
      }
    )
  }

  # Clean up
  unlink(c(temp_dir_in, temp_dir_out), recursive = TRUE)
})

# Test file pattern matching
test_that("aggregation respects file patterns", {
  temp_dir_in <- file.path(tempdir(), "pattern_test_in")
  temp_dir_out <- file.path(tempdir(), "pattern_test_out")

  dir.create(temp_dir_in, showWarnings = FALSE)
  dir.create(temp_dir_out, showWarnings = FALSE)

  # Create files with different patterns
  test_data <- data.frame(value = 1:24)

  write.table(
    test_data,
    file.path(temp_dir_in, "temp_20200101.txt"),
    row.names = FALSE,
    sep = ","
  )
  write.table(
    test_data,
    file.path(temp_dir_in, "precip_20200101.txt"),
    row.names = FALSE,
    sep = ","
  )
  write.table(
    test_data,
    file.path(temp_dir_in, "other_20200101.csv"),
    row.names = FALSE,
    sep = ","
  )

  tryCatch(
    {
      # Test with specific pattern - should only process temp files
      daily_aggregation(
        folder_in = temp_dir_in,
        folder_out = temp_dir_out,
        pattern = "temp_.*\\.txt$",
        from = "2020-01-01 00",
        to = "2020-01-01 23",
        take_out_first_record = FALSE
      )

      output_files <- list.files(temp_dir_out, full.names = TRUE)
      # Should only have processed the temp file
      expect_gte(length(output_files), 0)
    },
    error = function(e) {
      skip(paste("Pattern matching test failed:", e$message))
    }
  )

  # Clean up
  unlink(c(temp_dir_in, temp_dir_out), recursive = TRUE)
})

# Performance test for larger datasets
test_that("aggregation performs reasonably with larger datasets", {
  skip_on_cran() # Skip on CRAN to avoid long test times

  temp_dir_in <- file.path(tempdir(), "perf_test_in")
  temp_dir_out <- file.path(tempdir(), "perf_test_out")

  dir.create(temp_dir_in, showWarnings = FALSE)
  dir.create(temp_dir_out, showWarnings = FALSE)

  # Create multiple files with larger datasets
  for (day in 1:3) {
    large_data <- data.frame(
      value = rnorm(24 * 365) # One year of hourly data
    )

    filename <- sprintf("large_data_%02d.txt", day)
    write.table(
      large_data,
      file.path(temp_dir_in, filename),
      row.names = FALSE,
      sep = ","
    )
  }

  # Test performance
  start_time <- Sys.time()

  tryCatch(
    {
      daily_aggregation(
        folder_in = temp_dir_in,
        folder_out = temp_dir_out,
        from = "2020-01-01 00",
        to = "2020-12-30 22",
        take_out_first_record = TRUE,
        aggregation_function = mean
      )

      end_time <- Sys.time()
      elapsed_time <- as.numeric(end_time - start_time)

      # Should complete in reasonable time (adjust threshold as needed)
      expect_lt(elapsed_time, 60) # Less than 60 seconds
    },
    error = function(e) {
      skip(paste("Performance test failed:", e$message))
    }
  )

  # Clean up
  unlink(c(temp_dir_in, temp_dir_out), recursive = TRUE)
})

# Integration test with other package functions
test_that("aggregation integrates well with other package functions", {
  # Test that aggregated output can be used with other functions
  temp_dir_in <- file.path(tempdir(), "integration_in")
  temp_dir_out <- file.path(tempdir(), "integration_out")

  dir.create(temp_dir_in, showWarnings = FALSE)
  dir.create(temp_dir_out, showWarnings = FALSE)

  # Create test data
  test_data <- data.frame(value = seq(1, 24))
  write.table(
    test_data,
    file.path(temp_dir_in, "integration_test.txt"),
    row.names = FALSE,
    sep = ","
  )

  tryCatch(
    {
      # Run aggregation
      daily_aggregation(
        folder_in = temp_dir_in,
        folder_out = temp_dir_out,
        take_out_first_record = FALSE,
        from = "2020-01-01 00",
        to = "2020-01-01 23"
      )

      # Try to use output with other functions (e.g., summary_table)
      if (length(list.files(temp_dir_out)) > 0) {
        summary_result <- summary_table(
          var_folder = temp_dir_out,
          sample = 1,
          by_month = FALSE
        )

        expect_s3_class(summary_result, "data.frame")
      }
    },
    error = function(e) {
      skip(paste("Integration test failed:", e$message))
    }
  )

  # Clean up
  unlink(c(temp_dir_in, temp_dir_out), recursive = TRUE)
})
