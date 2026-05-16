# Tests for table_io.R

test_that("files_to_table works correctly", {
  temp_dir <- local_test_dir("files_to_table")
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

})

test_that("files_to_table handles missing files gracefully", {
  temp_dir <- local_test_dir("files_to_table_missing")

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
  temp_dir <- local_test_dir("files_to_table_na")
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

})

# Test table_to_files function

test_that("table_to_files works correctly", {
  temp_dir <- local_test_dir("table_to_files")
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

})

# Test count_na function

test_that("files_to_table can replace missing codes and clamp negatives", {
  input_dir <- local_test_dir("files_to_table_negatives")

  data.table::fwrite(
    data.frame(value = c(-1, -99, 3)),
    file.path(input_dir, "pcp_1.txt")
  )

  result <- files_to_table(
    files_path = input_dir,
    files_pattern = "pcp",
    start_date = "2020-01-01",
    end_date = "2020-01-03",
    na_value = -99,
    neg_to_zero = TRUE
  )

  expect_equal(result$pcp_1, c(0, NA, 3))
})

test_that("table I/O functions handle invalid inputs gracefully", {
  input_dir <- local_test_dir("table_io_invalid")

  expect_error(
    files_to_table(
      files_path = input_dir,
      files_pattern = "missing",
      start_date = "invalid-date",
      end_date = "2020-01-01"
    )
  )

  expect_error(
    table_to_files(
      table = "not a table",
      folder_path = local_test_dir("table_io_invalid_out"),
      first_date = "20200101"
    )
  )
})
