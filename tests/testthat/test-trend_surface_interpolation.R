# Tests for trend_surface_interpolation.R

test_that("ts_to_point returns one time series per target point", {
  skip_if_not_installed("sf")

  input_dir <- local_test_dir("ts_point_input")
  target_file <- local_test_file("ts_point_targets", ".gpkg")

  station_tbl <- data.frame(
    ID = 1:4,
    NAME = paste0("p", 1:4),
    LAT = c(0, 0, 1, 1),
    LON = c(0, 1, 0, 1),
    ELEVATION = c(10, 20, 30, 40),
    pcp = c(1, 2, 3, 4)
  )

  data.table::fwrite(station_tbl, file.path(input_dir, "2020-01-01.csv"))
  station_tbl$pcp <- station_tbl$pcp + 10
  data.table::fwrite(station_tbl, file.path(input_dir, "2020-01-02.csv"))

  target_points <- sf::st_as_sf(
    data.frame(
      OBJECTID = 1:2,
      Lon_dec = c(0.25, 0.75),
      Lat_dec = c(0.25, 0.75)
    ),
    coords = c("Lon_dec", "Lat_dec"),
    remove = FALSE,
    crs = 4326
  )
  sf::st_write(target_points, target_file, quiet = TRUE)

  result <- ts_to_point(
    my_folder = input_dir,
    targeted_points_path = target_file,
    poly_degree = 1
  )

  expect_type(result, "list")
  expect_length(result, 2)
  expect_equal(names(result), c("1", "2"))
  expect_equal(unique(result[[1]]$date), c("2020-01-01", "2020-01-02"))
  expect_true(all(result[[1]]$value >= 0))
  expect_true(all(result[[2]]$value > result[[1]]$value))
})

test_that("ts_to_point validates input files and arguments", {
  skip_if_not_installed("sf")

  input_dir <- local_test_dir("ts_point_validation_input")
  target_file <- local_test_file("ts_point_validation_target", ".gpkg")

  target_points <- sf::st_as_sf(
    data.frame(
      OBJECTID = 1,
      Lon_dec = 0.25,
      Lat_dec = 0.25
    ),
    coords = c("Lon_dec", "Lat_dec"),
    remove = FALSE,
    crs = 4326
  )
  sf::st_write(target_points, target_file, quiet = TRUE)

  expect_error(
    ts_to_point(
      my_folder = "/non/existent/path",
      targeted_points_path = target_file
    ),
    "my_folder"
  )
  expect_error(
    ts_to_point(
      my_folder = input_dir,
      targeted_points_path = "/non/existent/target.gpkg"
    ),
    "targeted_points_path"
  )
  expect_error(
    ts_to_point(
      my_folder = input_dir,
      targeted_points_path = target_file,
      poly_degree = 0
    ),
    "poly_degree"
  )
  expect_error(
    ts_to_point(
      my_folder = input_dir,
      targeted_points_path = target_file
    ),
    "No time-series files found"
  )

  data.table::fwrite(
    data.frame(
      ID = 1:4,
      NAME = paste0("p", 1:4),
      LAT = c(0, 0, 1, 1),
      LON = c(0, 1, 0, 1),
      ELEVATION = c(10, 20, 30, 40),
      value = c(1, 2, 3, 4)
    ),
    file.path(input_dir, "2020-01-01.csv")
  )

  bad_target_file <- local_test_file("ts_point_validation_bad_target", ".gpkg")
  bad_target_points <- sf::st_as_sf(
    data.frame(
      OBJECTID = 1,
      x = 0.25,
      y = 0.25
    ),
    coords = c("x", "y"),
    crs = 4326
  )
  sf::st_write(bad_target_points, bad_target_file, quiet = TRUE)

  expect_error(
    ts_to_point(
      my_folder = input_dir,
      targeted_points_path = bad_target_file,
      poly_degree = 1
    ),
    "Lon_dec"
  )

  expect_error(
    ts_to_point(
      my_folder = input_dir,
      targeted_points_path = target_file,
      poly_degree = 1
    ),
    "must contain 'pcp', 'LON', and 'LAT'"
  )
})

test_that("trend surface interpolation can create a raster brick", {
  skip_if_not_installed("sf")
  skip_if_not_installed("raster")

  input_dir <- local_test_dir("ts_area_input")
  basin_file <- local_test_file("ts_area_basin", ".gpkg")

  station_tbl <- data.frame(
    ID = 1:4,
    NAME = paste0("p", 1:4),
    LAT = c(0, 0, 1, 1),
    LON = c(0, 1, 0, 1),
    ELEVATION = c(10, 20, 30, 40),
    pcp = c(1, 2, 3, 4)
  )
  data.table::fwrite(station_tbl, file.path(input_dir, "2020-01-01.csv"))
  station_tbl$pcp <- station_tbl$pcp + 1
  data.table::fwrite(station_tbl, file.path(input_dir, "2020-01-02.csv"))

  basin <- sf::st_sf(
    id = 1,
    geometry = sf::st_sfc(
      sf::st_polygon(list(rbind(
        c(0, 0),
        c(1, 0),
        c(1, 1),
        c(0, 1),
        c(0, 0)
      ))),
      crs = 4326
    )
  )
  sf::st_write(basin, basin_file, quiet = TRUE)

  result <- ts_to_area(
    my_folder = input_dir,
    bassin_limit_path = basin_file,
    poly_degree = 1,
    resolution = 0.5
  )

  expect_s4_class(result, "RasterBrick")
  expect_equal(raster::nlayers(result), 2)
  expect_equal(names(result), c("X2020.01.01", "X2020.01.02"))
  expect_true(all(raster::values(result) >= 0))
})

test_that("ts_to_area validates input files and arguments", {
  skip_if_not_installed("sf")

  input_dir <- local_test_dir("ts_area_validation_input")
  basin_file <- local_test_file("ts_area_validation_basin", ".gpkg")

  basin <- sf::st_sf(
    id = 1,
    geometry = sf::st_sfc(
      sf::st_polygon(list(rbind(
        c(0, 0),
        c(1, 0),
        c(1, 1),
        c(0, 1),
        c(0, 0)
      ))),
      crs = 4326
    )
  )
  sf::st_write(basin, basin_file, quiet = TRUE)

  expect_error(
    ts_to_area(
      my_folder = "/non/existent/path",
      bassin_limit_path = basin_file
    ),
    "my_folder"
  )
  expect_error(
    ts_to_area(
      my_folder = input_dir,
      bassin_limit_path = "/non/existent/basin.gpkg"
    ),
    "bassin_limit_path"
  )
  expect_error(
    ts_to_area(
      my_folder = input_dir,
      bassin_limit_path = basin_file,
      resolution = 0
    ),
    "resolution"
  )
  expect_error(
    ts_to_area(
      my_folder = input_dir,
      bassin_limit_path = basin_file
    ),
    "No time-series files found"
  )

  data.table::fwrite(
    data.frame(
      ID = 1:4,
      NAME = paste0("p", 1:4),
      LAT = c(0, 0, 1, 1),
      LON = c(0, 1, 0, 1),
      ELEVATION = c(10, 20, 30, 40),
      value = c(1, 2, 3, 4)
    ),
    file.path(input_dir, "2020-01-01.csv")
  )

  expect_error(
    ts_to_area(
      my_folder = input_dir,
      bassin_limit_path = basin_file,
      poly_degree = 1
    ),
    "must contain 'pcp', 'LON', and 'LAT'"
  )
})
