# Tests for internal_files.R

test_that("utility file-system helpers create, return, and clean directories", {
  helper_dir <- file.path(
    local_test_dir("wcswatin_helper_parent"),
    "helper_dir"
  )

  created_path <- wcswatin:::touch_dir(helper_dir, return_path = TRUE)
  expect_equal(created_path, helper_dir)
  expect_true(dir.exists(helper_dir))

  writeLines("x", file.path(helper_dir, "x.txt"))
  wcswatin:::clean_dir(helper_dir)
  expect_false(dir.exists(helper_dir))
})
