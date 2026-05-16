# Tests for data_quality.R

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

test_that("count_na handles invalid inputs gracefully", {
  expect_error(count_na("not a data frame"))
})

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
