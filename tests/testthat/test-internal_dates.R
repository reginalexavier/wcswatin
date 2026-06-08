# Tests for internal_dates.R

test_that("names_to_date extracts timestamps from raster layer names", {
  skip_if_not_installed("terra")

  cube <- c(
    terra::rast(nrows = 1, ncols = 1, vals = 1),
    terra::rast(nrows = 1, ncols = 1, vals = 2)
  )
  names(cube) <- c("time=0", "time=86400")

  result <- wcswatin:::names_to_date(cube)

  expect_equal(
    as.Date(result),
    as.Date(c("1970-01-01", "1970-01-02"))
  )
})
