# Tests for raster_metadata.R

test_that("var_names requires valid input", {
  # This test mainly checks parameter validation
  # since creating actual NetCDF files is complex
  expect_error(var_names("non_existent_file.nc"))
})
