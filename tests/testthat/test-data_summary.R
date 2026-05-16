# Tests for data_summary.R

test_that("summary_table computes monthly summaries with percent sample", {
  input_dir <- create_test_dir("summary_table_monthly")
  on.exit(unlink(input_dir, recursive = TRUE), add = TRUE)

  data.table::fwrite(
    data.frame(value = c(1, 2, 3, 4)),
    file.path(input_dir, "station_1.txt")
  )
  data.table::fwrite(
    data.frame(value = c(10, 20, 30, 40)),
    file.path(input_dir, "station_2.txt")
  )

  set.seed(123)
  result <- summary_table(
    var_folder = input_dir,
    sample = 50,
    percent = TRUE,
    by_month = TRUE,
    from = "2020-01-01",
    to = "2020-01-04",
    pattern = "station_.*\\.txt$"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(as.character(result$Month), "Jan")
  expect_true(all(c("min", "max", "mean", "sd", "n") %in% names(result)))
  expect_equal(result$n, 4)
})

test_that("summary_plot respects percent-based sampling", {
  input_dir <- create_test_dir("summary_plot_percent")
  on.exit(unlink(input_dir, recursive = TRUE), add = TRUE)

  data.table::fwrite(
    data.frame(value = c(1, 2, 3, 4)),
    file.path(input_dir, "station_1.txt")
  )
  data.table::fwrite(
    data.frame(value = c(10, 20, 30, 40)),
    file.path(input_dir, "station_2.txt")
  )

  set.seed(123)
  result <- summary_plot(
    var_folder = input_dir,
    sample = 50,
    percent = TRUE,
    from = "2020-01-01",
    to = "2020-01-04",
    pattern = "station_.*\\.txt$"
  )

  expect_s3_class(result, "ggplot")
  expect_equal(nrow(result$data), 4)
  expect_equal(length(unique(result$data$var_file)), 1)
})

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
