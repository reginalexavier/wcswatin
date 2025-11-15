# Test configuration and setup
# This file contains common setup for all tests

# Set up test environment
options(warn = 1) # Show warnings immediately

# Helper function to create temporary test directories
create_test_dir <- function(name = "test") {
  test_dir <- file.path(
    tempdir(),
    paste0(name, "_", Sys.getpid(), "_", sample(1000, 1))
  )
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  return(test_dir)
}

# Helper function to clean up test directories
cleanup_test_dir <- function(test_dir) {
  if (dir.exists(test_dir)) {
    unlink(test_dir, recursive = TRUE)
  }
}

# Helper function to skip tests based on package availability
skip_if_package_not_available <- function(package_name) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    testthat::skip(paste("Package", package_name, "not available"))
  }
}

# Common test data generators
generate_test_points <- function(n = 5) {
  data.frame(
    NAME = paste0("station_", 1:n),
    LAT = runif(n, -1, 1),
    LONG = runif(n, -1, 1),
    ELEVATION = runif(n, 0, 1000)
  )
}

generate_test_timeseries <- function(n_days = 30, n_stations = 3) {
  dates <- seq(as.Date("2020-01-01"), length.out = n_days, by = "day")

  data.frame(
    date = rep(dates, n_stations),
    station = rep(paste0("station_", 1:n_stations), each = n_days),
    value = rnorm(n_days * n_stations, mean = 20, sd = 5)
  )
}

# Test data with known missing values
generate_test_data_with_na <- function(n_rows = 100, na_prob = 0.1) {
  data.frame(
    col1 = ifelse(runif(n_rows) < na_prob, NA, rnorm(n_rows)),
    col2 = ifelse(runif(n_rows) < na_prob, NA, rnorm(n_rows)),
    col3 = ifelse(runif(n_rows) < na_prob, NA, rnorm(n_rows))
  )
}

# Test for package version compatibility
check_package_version <- function() {
  r_version <- R.version.string
  testthat::expect_true(grepl("R version", r_version))
}

# Setup function to run before all tests
setup_test_environment <- function() {
  # Set random seed for reproducible tests
  set.seed(42)

  # Check R version
  check_package_version()

  # Ensure required directories exist
  temp_base <- tempdir()
  if (!dir.exists(temp_base)) {
    dir.create(temp_base, recursive = TRUE)
  }
}

# Cleanup function to run after all tests
cleanup_test_environment <- function() {
  # Clean up any remaining temporary files
  temp_files <- list.files(tempdir(), pattern = "^test_", full.names = TRUE)
  if (length(temp_files) > 0) {
    unlink(temp_files, recursive = TRUE)
  }
}

# Run setup
setup_test_environment()
