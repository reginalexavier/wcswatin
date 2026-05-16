# Tests for package loading

test_that("package loads correctly", {
  expect_true(require(wcswatin))
})

# Test files_to_table function
