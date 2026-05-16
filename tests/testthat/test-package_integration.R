# Tests for package-level functions and integration
# Testing overall package functionality and integration between components

# Test package loading and basic structure
test_that("package loads correctly and has expected structure", {
  # Test that package loads without errors
  expect_true(require(wcswatin))

  # Test that main functions are available
  expected_functions <- c(
    "files_to_table",
    "table_to_files",
    "point_to_daily",
    "count_na",
    "var_names",
    "fill_gap",
    "tbl_from_references",
    "unit_converter",
    "summary_table",
    "summary_plot"
  )

  for (func in expected_functions) {
    expect_true(
      exists(func, where = "package:wcswatin"),
      info = paste("Function", func, "not found")
    )
  }
})


# Test package example data
test_that("package example data is accessible and well-formed", {
  # Test precipitation station data
  pcp_file <- system.file(
    "extdata/pcp_stations/pcp.txt",
    package = "wcswatin"
  )

  if (file.exists(pcp_file)) {
    pcp_data <- read.csv(pcp_file)

    expect_s3_class(pcp_data, "data.frame")
    expect_gt(nrow(pcp_data), 0)

    # Check expected columns
    expected_cols <- c("ID", "NAME", "LAT", "LONG", "ELEVATION")
    expect_true(
      all(expected_cols %in% names(pcp_data)),
      info = "Expected columns missing from precipitation data"
    )

    # Check data quality
    expect_true(all(!is.na(pcp_data$LAT)))
    expect_true(all(!is.na(pcp_data$LONG)))
    expect_true(all(pcp_data$LAT >= -90 & pcp_data$LAT <= 90))
    expect_true(all(pcp_data$LONG >= -180 & pcp_data$LONG <= 180))
  } else {
    skip("Precipitation station data not found")
  }
})

# Test integration workflow: file processing
test_that("complete file processing workflow works", {
  # Test the typical workflow from files to processed data

  # Check if example data is available
  pcp_folder <- system.file("extdata/pcp_stations", package = "wcswatin")

  if (dir.exists(pcp_folder)) {
    # Test point_to_daily function with example data
    result <- point_to_daily(
      my_folder = pcp_folder,
      start_date = "20170301",
      end_date = "20170331" # Small date range for testing
    )

    expect_type(result, "list")
    expect_gt(length(result), 0)

    # Test that result can be saved
    temp_dir <- local_test_dir("integration_file_workflow")
    save_daily_tbl(tbl_list = result, path = temp_dir)

    # Check that files were created
    saved_files <- list.files(
      temp_dir,
      pattern = "day_.*\\.csv",
      full.names = TRUE
    )
    expect_gt(length(saved_files), 0)

    # Test that saved files can be read back
    if (length(saved_files) > 0) {
      read_back <- read.csv(saved_files[1])
      expect_s3_class(read_back, "data.frame")
      expect_gt(nrow(read_back), 0)
    }

  } else {
    skip("Example precipitation data not available")
  }
})

# Test integration workflow: data quality assessment
test_that("data quality assessment workflow works", {
  # Create test dataset with known quality issues
  test_data <- data.frame(
    date = seq(as.Date("2020-01-01"), as.Date("2020-01-10"), by = "day"),
    station1 = c(1, 2, NA, 4, 5, NA, 7, 8, 9, 10),
    station2 = c(10, 9, 8, 7, 6, 5, 4, 3, 2, 1),
    station3 = c(NA, NA, 3, 4, 5, 6, 7, 8, NA, 10)
  )

  # Test NA counting
  na_summary <- count_na(test_data, percent = TRUE)

  expect_s3_class(na_summary, "data.frame")
  expect_equal(nrow(na_summary), 4) # 4 columns

  # Check that NA percentages are calculated correctly
  station1_na_pct <- na_summary$Prop_NA[na_summary$column == "station1"]
  expect_equal(station1_na_pct, 20) # 2 out of 10 = 20%

  station3_na_pct <- na_summary$Prop_NA[na_summary$column == "station3"]
  expect_equal(station3_na_pct, 30) # 3 out of 10 = 30%
})

# Test integration workflow: unit conversion
test_that("unit conversion workflow works", {
  # Create test temperature data in Kelvin
  temp_dir_in <- local_test_dir("temp_kelvin")
  temp_dir_out <- local_test_dir("temp_celsius")

  # Create test file with Kelvin temperatures
  kelvin_data <- data.frame(
    temperature = c(273.15, 283.15, 293.15, 303.15)
  )

  test_file <- file.path(temp_dir_in, "temp_20200101.txt")
  write.table(kelvin_data, test_file, row.names = FALSE, sep = ",")

  # Test unit conversion
  unit_converter(
    folder_in = temp_dir_in,
    folder_out = temp_dir_out,
    FUN = function(x) x - 273.15 # Kelvin to Celsius
  )

  # Check results
  output_files <- list.files(temp_dir_out, full.names = TRUE)
  expect_gt(length(output_files), 0)

  if (length(output_files) > 0) {
    celsius_data <- read.table(output_files[1], header = TRUE, sep = ",")
    expected_celsius <- c(0, 10, 20, 30)
    expect_equal(celsius_data$temperature, expected_celsius)
  }

})

# Test integration workflow: summary statistics
test_that("summary statistics workflow works", {
  test_dir <- local_test_dir("summary_test")

  # Create multiple data files
  for (i in 1:3) {
    test_data <- data.frame(
      value = rnorm(30, mean = i * 10, sd = 2) # Different means for each file
    )

    filename <- file.path(test_dir, paste0("station_", i, ".txt"))
    write.table(test_data, filename, row.names = FALSE)
  }

  # Test summary table generation
  summary_result <- summary_table(
    var_folder = test_dir,
    sample = 2,
    by_month = FALSE
  )

  expect_s3_class(summary_result, "data.frame")
  expect_true(all(
    c("min", "max", "mean", "sd", "n") %in% names(summary_result)
  ))

  # Test summary plot generation
  plot_result <- summary_plot(
    var_folder = test_dir,
    sample = 2,
    from = "2020-01-01",
    to = "2020-01-30"
  )

  expect_s3_class(plot_result, "ggplot")

})

# Test error handling across package functions
test_that("package functions handle errors consistently", {
  # Test with invalid file paths
  expect_error(
    files_to_table(
      files_path = "/non/existent/path",
      files_pattern = "test"
    )
  )

  expect_error(
    point_to_daily(
      my_folder = "/non/existent/path"
    )
  )

  expect_error(
    summary_table(
      var_folder = "/non/existent/path"
    )
  )

  # Test with invalid data
  expect_error(count_na("not a data frame"))

  expect_error(
    table_to_files(
      table = "not a table",
      folder_path = local_test_dir("package_invalid_table_out"),
      first_date = "20200101"
    )
  )
})
