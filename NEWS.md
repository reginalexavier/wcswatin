# wcswatin (development version)

# wcswatin 0.1.1

## Maintenance

* Minor maintenance release following CRAN pre-submission checks.
* Added package-specific terms to `inst/WORDLIST`.
* Excluded `cran-comments.md` from the source package.
* Updated package metadata and README citation examples to version 0.1.1.

# wcswatin 0.1.0

## Package workflows and structure

* Reorganized R source files by logical domain, making the package structure
  match the main workflows more closely.
* Reorganized the test suite by the same logical domains and added shared test
  helpers for temporary files and directories.
* Added compact NetCDF example files to support runnable examples, metadata
  inspection, and raster workflow tests.
* Replaced the previous Makefile-based workflow with a `justfile` for common
  development tasks.

## New features

* Added `raster_info()` to summarize raster and NetCDF metadata, including
  variables, units, layer counts, spatial extent, CRS, and time range.
* Added `ts_point_to_files()` to save `ts_to_point()` outputs as individual
  SWAT-style point files.
* Added `value_at_hour` support to `daily_aggregation()` for products whose
  daily value is stored at a specific hour.
* Added `value_at_hour`, `date_shift_days`, and `drop_first_layer` support to
  `datacube_aggregation()` so hourly raster cubes can be reduced before
  extraction.
* Improved `tbl_from_references()` so reference points can be supplied using
  the package's standard table, vector, and path input patterns.

## Breaking changes

* Standardized longitude column names to `LON`.
* Renamed the `take_out_first_record` argument in `daily_aggregation()` to
  `drop_first_record`.
* Renamed the `negatif_number` argument in station/table preprocessing to
  `neg_to_zero`.

## Bug fixes and validation

* Added reusable input validation helpers and clearer error messages across
  raster, table, station, and interpolation workflows.
* Ensured variable derivation helpers create output directories consistently.
* Removed a duplicate internal `file_name()` implementation.
* Removed the `vroom` dependency from the main file-reading workflow.
* Expanded test coverage for raster aggregation, cube extraction, metadata,
  reference extraction, station input, table aggregation, table I/O, variable
  derivation, and trend-surface interpolation.

## Documentation

* Added a lightweight executable vignette using bundled example data.
* Added precomputed pkgdown articles for:
  * ERA5-Land hourly data to SWAT inputs;
  * station interpolation workflow;
  * running a similar external case study.
* Updated README and pkgdown navigation to reflect the current package
  workflows.

# wcswatin 0.0.1

## First Release

Initial release of wcswatin (Weather & Climate SWAT INput) package for preparing weather and climate data for input in the Soil & Water Assessment Tool (SWAT).

### Features

* Process NetCDF and GeoTIFF raster files from multiple climate data providers
* Temporal and spatial aggregation tools
* Gap filling and missing data handling
* Unit conversion utilities for weather variables
* Summary statistics and visualization functions
* File management and batch processing utilities

### Infrastructure

* Comprehensive test suite with cross-platform support (Windows, macOS, Linux)
* CI/CD with GitHub Actions (R-CMD-check, test-coverage, pkgdown)
* Documentation website available at <https://reginalexavier.github.io/wcswatin/>
