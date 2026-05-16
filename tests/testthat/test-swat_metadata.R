# Tests for swat_metadata.R

test_that("main_input_var builds metadata names from study area IDs", {
  study_area <- data.frame(
    ID = c(4, 8),
    LAT = c(1.5, 0.5),
    LON = c(0.5, 1.5),
    ELEVATION = c(104, 108)
  )

  result <- main_input_var(study_area, var_name = "tas")

  expect_s3_class(result, "data.table")
  expect_equal(names(result), c("ID", "NAME", "LAT", "LON", "ELEVATION"))
  expect_equal(result$NAME, c("tas_4", "tas_8"))
})

test_that("var_main_creator preserves coordinates and metadata", {
  skip_if_not_installed("sf")

  target_file <- file.path(tempdir(), "main_creator_targets.gpkg")
  on.exit(unlink(target_file, recursive = TRUE), add = TRUE)

  target_points <- sf::st_as_sf(
    data.frame(
      OBJECTID = c(11, 12),
      Elev = c(123, 456),
      lon = c(-54.1, -54.2),
      lat = c(-15.1, -15.2)
    ),
    coords = c("lon", "lat"),
    crs = 4326
  )
  sf::st_write(target_points, target_file, quiet = TRUE)

  result <- var_main_creator(target_file, var_name = "pcp", col_elev = "Elev")

  expect_equal(names(result), c("ID", "NAME", "LAT", "LONG", "ELEVATION"))
  expect_equal(result$ID, c(11, 12))
  expect_equal(result$NAME, c("pcp1", "pcp2"))
  expect_equal(result$LAT, c(-15.1, -15.2))
  expect_equal(result$LONG, c(-54.1, -54.2))
  expect_equal(result$ELEVATION, c(123, 456))
})
