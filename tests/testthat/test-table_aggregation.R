# Tests for table_aggregation.R

test_that("daily_aggregation creates proper file structure", {
  temp_dir_in <- local_test_dir("agg_test_in")
  temp_dir_out <- local_test_dir("agg_test_out")

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
    drop_first_record = FALSE,
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
})

test_that("daily_aggregation handles different aggregation modes", {
  temp_dir_in <- local_test_dir("mode_test_in")
  temp_dir_out <- local_test_dir("mode_test_out")

  # Create test data with known values for testing
  hourly_data <- data.frame(
    value = c(1:12, 12:1) # 24 values with known pattern
  )

  test_file <- file.path(temp_dir_in, "test_20200101.txt")
  write.table(hourly_data, test_file, row.names = FALSE, sep = ",")

  daily_aggregation(
    folder_in = temp_dir_in,
    folder_out = temp_dir_out,
    from = "2020-01-01 00",
    to = "2020-01-01 23",
    drop_first_record = FALSE,
    aggregation_function = sum
  )

  result <- data.table::fread(file.path(temp_dir_out, "test_20200101.txt"))
  expect_equal(result[[1]], sum(hourly_data$value))
})

test_that("daily_aggregation handles missing data appropriately", {
  temp_dir_in <- local_test_dir("na_test_in")
  temp_dir_out <- local_test_dir("na_test_out")

  # Create test data with NA values
  hourly_data <- data.frame(
    value = c(1:10, rep(NA, 6), 11:18) # 24 values with NAs
  )

  test_file <- file.path(temp_dir_in, "test_na_20200101.txt")
  write.table(hourly_data, test_file, row.names = FALSE, sep = ",")

  daily_aggregation(
    folder_in = temp_dir_in,
    folder_out = temp_dir_out,
    from = "2020-01-01 00",
    to = "2020-01-01 23",
    drop_first_record = FALSE,
    aggregation_function = mean,
    na.rm = TRUE
  )

  result <- data.table::fread(file.path(temp_dir_out, "test_na_20200101.txt"))
  expect_equal(result[[1]], mean(stats::na.omit(hourly_data$value)))
})

test_that("daily_aggregation validates input parameters", {
  temp_dir_in <- local_test_dir("daily_invalid_in")
  temp_dir_out <- local_test_dir("daily_invalid_out")

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
    "format 'YYYY-MM-DD HH'"
  )

  # Test with non-existent input directory
  expect_error(
    {
      daily_aggregation(
        folder_in = "/non/existent/path",
        folder_out = temp_dir_out,
        from = "2020-01-01 00",
        to = "2020-01-01 23",
        drop_first_record = FALSE
      )
    },
    "folder_in"
  )

  expect_error(
    {
      daily_aggregation(
        folder_in = temp_dir_in,
        folder_out = temp_dir_out,
        from = "2020-01-01 00",
        to = "2020-01-01 23",
        value_hour = 24
      )
    },
    "value_hour"
  )
})

test_that("daily_aggregation validates hourly record count", {
  input_dir <- local_test_dir("daily_record_count_input")
  output_dir <- local_test_dir("daily_record_count_output")

  data.table::fwrite(
    data.frame(value = 1:3),
    file.path(input_dir, "short_20200101.txt")
  )

  expect_error(
    daily_aggregation(
      folder_in = input_dir,
      folder_out = output_dir,
      from = "2020-01-01 00",
      to = "2020-01-01 23",
      drop_first_record = FALSE
    ),
    "date range has 24 hours"
  )
})

test_that("daily_aggregation supports max-min and value-at-hour modes", {
  input_dir <- local_test_dir("daily_modes_input")
  max_min_dir <- local_test_dir("daily_modes_max_min")
  value_at_zero_dir <- local_test_dir("daily_modes_value_at_zero")
  value_at_zero_drop_dir <- local_test_dir("daily_modes_value_at_zero_drop")
  value_at_23_dir <- local_test_dir("daily_modes_value_at_23")

  data.table::fwrite(
    data.frame(value = 1:24),
    file.path(input_dir, "tas_20200101.txt")
  )

  daily_aggregation(
    folder_in = input_dir,
    folder_out = max_min_dir,
    from = "2020-01-01 00",
    to = "2020-01-01 23",
    drop_first_record = FALSE,
    mode = "max_min"
  )
  max_min_lines <- readLines(file.path(max_min_dir, "tas_20200101.txt"))
  expect_equal(max_min_lines, c("value", "24,1"))

  daily_aggregation(
    folder_in = input_dir,
    folder_out = value_at_zero_dir,
    from = "2020-01-01 01",
    to = "2020-01-02 00",
    drop_first_record = FALSE,
    mode = "value_at_hour"
  )
  value_at_zero <- data.table::fread(
    file.path(value_at_zero_dir, "tas_20200101.txt")
  )
  expect_equal(value_at_zero[[1]], 24L)

  data.table::fwrite(
    data.frame(value = c(999, 1:24)),
    file.path(input_dir, "pcp_20200101.txt")
  )

  daily_aggregation(
    folder_in = input_dir,
    folder_out = value_at_zero_drop_dir,
    pattern = "^pcp_.*\\.txt$",
    from = "2020-01-01 01",
    to = "2020-01-02 00",
    drop_first_record = TRUE,
    mode = "value_at_hour"
  )
  value_at_zero_drop <- data.table::fread(
    file.path(value_at_zero_drop_dir, "pcp_20200101.txt")
  )
  expect_equal(value_at_zero_drop[[1]], 24L)

  daily_aggregation(
    folder_in = input_dir,
    folder_out = value_at_23_dir,
    pattern = "^tas_.*\\.txt$",
    from = "2020-01-01 00",
    to = "2020-01-01 23",
    drop_first_record = FALSE,
    mode = "value_at_hour",
    value_hour = 23
  )
  value_at_23 <- data.table::fread(
    file.path(value_at_23_dir, "tas_20200101.txt")
  )
  expect_equal(value_at_23[[1]], 24L)
})

test_that("daily_aggregation drops the first record when requested", {
  input_dir <- local_test_dir("daily_drop_input")
  output_dir <- local_test_dir("daily_drop_output")

  data.table::fwrite(
    data.frame(value = c(999, rep(1, 24))),
    file.path(input_dir, "pcp_20200101.txt")
  )

  daily_aggregation(
    folder_in = input_dir,
    folder_out = output_dir,
    from = "2020-01-01 00",
    to = "2020-01-01 23",
    drop_first_record = TRUE,
    aggregation_function = sum
  )

  result <- data.table::fread(file.path(output_dir, "pcp_20200101.txt"))
  expect_equal(result[[1]], 24)
})


# Test temporal aggregation utilities

test_that("temporal aggregation handles edge cases", {
  # Test with single hour data
  temp_dir_in <- local_test_dir("edge_test_in")
  temp_dir_out <- local_test_dir("edge_test_out")

  # Single value data
  single_data <- data.frame(value = 42)
  test_file <- file.path(temp_dir_in, "single_20200101.txt")
  write.table(single_data, test_file, row.names = FALSE, sep = ",")

  daily_aggregation(
    folder_in = temp_dir_in,
    folder_out = temp_dir_out,
    from = "2020-01-01 00",
    to = "2020-01-01 00",
    drop_first_record = FALSE,
    aggregation_function = mean
  )

  result <- data.table::fread(file.path(temp_dir_out, "single_20200101.txt"))
  expect_equal(result[[1]], 42)
})

# Test aggregation with different functions

test_that("aggregation works with different statistical functions", {
  temp_dir_in <- local_test_dir("stat_test_in")
  temp_dir_out <- local_test_dir("stat_test_out")

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

    daily_aggregation(
      folder_in = temp_dir_in,
      folder_out = output_subdir,
      from = "2020-01-01 00",
      to = "2020-01-01 23",
      drop_first_record = FALSE,
      aggregation_function = func,
      na.rm = TRUE
    )

    result <- data.table::fread(
      file.path(output_subdir, "stat_test_20200101.txt")
    )
    expect_equal(result[[1]], func(test_values, na.rm = TRUE))
  }
})

# Test file pattern matching

test_that("aggregation respects file patterns", {
  temp_dir_in <- local_test_dir("pattern_test_in")
  temp_dir_out <- local_test_dir("pattern_test_out")

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

  daily_aggregation(
    folder_in = temp_dir_in,
    folder_out = temp_dir_out,
    pattern = "temp_.*\\.txt$",
    from = "2020-01-01 00",
    to = "2020-01-01 23",
    drop_first_record = FALSE
  )

  expect_equal(list.files(temp_dir_out), "temp_20200101.txt")
})

# Integration test with other package functions

test_that("aggregation integrates well with other package functions", {
  # Test that aggregated output can be used with other functions
  temp_dir_in <- local_test_dir("integration_in")
  temp_dir_out <- local_test_dir("integration_out")

  # Create test data
  test_data <- data.frame(value = seq(1, 24))
  write.table(
    test_data,
    file.path(temp_dir_in, "integration_test.txt"),
    row.names = FALSE,
    sep = ","
  )

  daily_aggregation(
    folder_in = temp_dir_in,
    folder_out = temp_dir_out,
    drop_first_record = FALSE,
    from = "2020-01-01 00",
    to = "2020-01-01 23"
  )

  summary_result <- summary_table(
    var_folder = temp_dir_out,
    sample = 1,
    by_month = FALSE
  )

  expect_s3_class(summary_result, "data.frame")
})
