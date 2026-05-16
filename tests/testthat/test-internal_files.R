# Tests for internal_files.R

test_that("utility file-system helpers create, return, and clean directories", {
  helper_dir <- file.path(tempdir(), "wcswatin_helper_dir")
  on.exit(unlink(helper_dir, recursive = TRUE), add = TRUE)

  created_path <- wcswatin:::touch_dir(helper_dir, return_path = TRUE)
  expect_equal(created_path, helper_dir)
  expect_true(dir.exists(helper_dir))

  writeLines("x", file.path(helper_dir, "x.txt"))
  wcswatin:::clean_dir(helper_dir)
  expect_false(dir.exists(helper_dir))
})
