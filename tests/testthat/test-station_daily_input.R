# Tests for station_daily_input.R

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

  temp_dir <- local_test_dir("save_daily_tbl")

  save_daily_tbl(tbl_list = test_list, path = temp_dir)

  # Check files were created
  expect_true(file.exists(file.path(temp_dir, "day_2020-01-01.csv")))
  expect_true(file.exists(file.path(temp_dir, "day_2020-01-02.csv")))

  # Check file contents
  file1_content <- read.csv(file.path(temp_dir, "day_2020-01-01.csv"))
  expect_equal(nrow(file1_content), 3)
  expect_equal(file1_content$value, c(1, 2, 3))

})

# Error handling tests
