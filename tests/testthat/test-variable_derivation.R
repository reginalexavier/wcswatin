# Tests for variable_derivation.R

test_that("unit_converter works correctly", {
  skip_on_cran()

  temp_dir_in <- local_test_dir("unit_converter_in")
  temp_dir_out <- local_test_dir("unit_converter_out")

  # Create test file with Kelvin temperatures
  test_file <- file.path(temp_dir_in, "temp_20200101.txt")
  kelvin_temps <- data.frame(temperature = c(273.15, 283.15, 293.15))
  data.table::fwrite(
    kelvin_temps,
    test_file
  )

  # Verify input file was created
  expect_true(file.exists(test_file))
  expect_equal(
    list.files(temp_dir_in, pattern = "^temp_20200101\\.txt$"),
    "temp_20200101.txt"
  )
  expect_equal(
    readLines(test_file),
    c("temperature", "273.15", "283.15", "293.15")
  )

  # Test conversion (Kelvin to Celsius)
  unit_converter(
    folder_in = temp_dir_in,
    folder_out = temp_dir_out,
    pattern = "^temp_20200101\\.txt$",
    FUN = function(x) x - 273.15
  )

  # Check output directory has files
  output_files <- list.files(temp_dir_out, pattern = ".txt$", full.names = TRUE)
  expect_true(length(output_files) > 0)

  # Check specific output file
  output_file <- file.path(temp_dir_out, "temp_20200101.txt")

  # Debug: print available files if test fails
  if (!file.exists(output_file)) {
    message("Output file not found. Available files in output directory:")
    message(paste(list.files(temp_dir_out, full.names = TRUE), collapse = "\n"))
  }

  expect_true(file.exists(output_file))

  result <- read.table(output_file, header = TRUE, sep = ",")
  expect_equal(result$temperature[1], 0, tolerance = 0.01)
  expect_equal(result$temperature[2], 10, tolerance = 0.01)
  expect_equal(result$temperature[3], 20, tolerance = 0.01)

})

test_that("unit_converter validates input files and transformation function", {
  input_dir <- local_test_dir("unit_converter_invalid")
  output_dir <- local_test_dir("unit_converter_invalid_out")

  expect_error(
    unit_converter(input_dir, output_dir, FUN = "not a function"),
    "must be a function"
  )

  expect_error(
    unit_converter(input_dir, output_dir),
    "No input files found"
  )
})

test_that("rh_calculator writes relative humidity from paired files", {
  dpt_dir <- local_test_dir("rh_dpt")
  tas_dir <- local_test_dir("rh_tas")
  parent_dir <- local_test_dir("rh_parent")
  output_dir <- file.path(parent_dir, "rh_output")

  data.table::fwrite(
    data.frame(temp = c(10, 15)),
    file.path(dpt_dir, "dpt_20200101.txt")
  )
  data.table::fwrite(
    data.frame(temp = c(10, 20)),
    file.path(tas_dir, "tas_20200101.txt")
  )

  rh_calculator(dpt_dir, tas_dir, output_dir, file_name_output = "rh")

  expect_true(dir.exists(output_dir))
  output <- data.table::fread(file.path(output_dir, "rh20200101.txt"))
  expect_equal(names(output), "temp")
  expect_equal(output[[1]][1], 100)
  expect_lt(output[[1]][2], 100)
})

test_that("rh_calculator validates paired input files", {
  dpt_dir <- local_test_dir("rh_dpt_invalid")
  tas_dir <- local_test_dir("rh_tas_invalid")
  output_dir <- local_test_dir("rh_output_invalid")

  data.table::fwrite(
    data.frame(temp = c(10, 15)),
    file.path(dpt_dir, "dpt_20200101.txt")
  )

  expect_error(
    rh_calculator(dpt_dir, tas_dir, output_dir),
    "No temperature files found"
  )

  data.table::fwrite(
    data.frame(temp = 10),
    file.path(tas_dir, "tas_20200101.txt")
  )

  expect_error(
    rh_calculator(dpt_dir, tas_dir, output_dir),
    "same number of rows"
  )
})

test_that("windspeed_calculator writes vector magnitude from component files", {
  uas_dir <- local_test_dir("uas")
  vas_dir <- local_test_dir("vas")
  parent_dir <- local_test_dir("ws_parent")
  output_dir <- file.path(parent_dir, "ws_output")

  data.table::fwrite(
    data.frame(value = c(3, 5)),
    file.path(uas_dir, "uas_20200101.txt")
  )
  data.table::fwrite(
    data.frame(value = c(4, 12)),
    file.path(vas_dir, "vas_20200101.txt")
  )

  windspeed_calculator(
    folder_uas = uas_dir,
    folder_vas = vas_dir,
    folder_out = output_dir,
    col_name = "wind"
  )

  output_files <- list.files(
    output_dir,
    pattern = "^ws.*\\.txt$",
    full.names = TRUE
  )
  expect_true(dir.exists(output_dir))
  expect_length(output_files, 1)

  output <- data.table::fread(output_files)
  expect_equal(names(output), "wind")
  expect_equal(output[[1]], c(5, 13))
})

test_that("windspeed_calculator validates paired input files", {
  uas_dir <- local_test_dir("uas_invalid")
  vas_dir <- local_test_dir("vas_invalid")
  output_dir <- local_test_dir("ws_output_invalid")

  data.table::fwrite(
    data.frame(value = c(3, 5)),
    file.path(uas_dir, "uas_20200101.txt")
  )

  expect_error(
    windspeed_calculator(uas_dir, vas_dir, output_dir),
    "No northward wind files found"
  )

  data.table::fwrite(
    data.frame(value = 4),
    file.path(vas_dir, "vas_20200101.txt")
  )

  expect_error(
    windspeed_calculator(uas_dir, vas_dir, output_dir),
    "same number of rows"
  )
})
