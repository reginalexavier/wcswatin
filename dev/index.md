# wcswatin

## Overview

**wcswatin** (Weather & Climate SWAT Input) is an open-source R package
for preparing weather and climate data from different sources for input
in the [Soil & Water Assessment Tool (SWAT)](https://swat.tamu.edu/).

The package provides two main workflows:

- **Raster/NetCDF Processing**: Extract and process climate data from
  global gridded datasets (ERA5-Land, GPM IMERG, PERSIANN, etc.)
- **Station Data Interpolation**: Upscale point measurements from
  weather stations using trend surface interpolation

Developed with funding from the [Critical Ecosystem Partnership Fund
(CEPF)](https://www.cepf.net/).

## Key Features

- Process NetCDF and GeoTIFF raster files from multiple climate data
  providers
- Spatial and temporal data extraction for specific watersheds
- Trend surface interpolation for station data upscaling
- Gap-filling routines for station data
- Direct output formatting for SWAT model input files
- Optimized for large datasets with parallel processing support

## Installation

Install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("reginalexavier/wcswatin")
```

## Quick Start

``` r
library(wcswatin)

# Process NetCDF climate data
climate_data <- input_raster(
  raster_file = "path/to/climate_data.nc",
  watershed = "path/to/watershed.shp",
  var_name = "precipitation"
)

# Interpolate station data
station_data <- ts_to_point(
  my_folder = "path/to/station_files",
  targeted_points_path = "path/to/centroids.shp",
  poly_degree = 2
)
```

## Workflow Overview

![Conceptual workflow of the wcswatin
package](reference/figures/wcswatin_flowchart150222.png)

Conceptual workflow of the wcswatin package

## Main Functions

### Data Input & Loading

- [`input_raster()`](https://reginalexavier.github.io/wcswatin/dev/reference/input_raster.md):
  Load NetCDF or GeoTIFF files as SpatRaster objects
- [`input_table()`](https://reginalexavier.github.io/wcswatin/dev/reference/input_table.md):
  Load tabular data with validation
- [`input_vector()`](https://reginalexavier.github.io/wcswatin/dev/reference/input_vector.md):
  Load spatial vector data (shapefiles, etc.)
- [`var_names()`](https://reginalexavier.github.io/wcswatin/dev/reference/var_names.md):
  List available variables in NetCDF files

### Raster/NetCDF Processing

- [`study_area_records()`](https://reginalexavier.github.io/wcswatin/dev/reference/study_area_records.md):
  Extract grid points within watershed boundaries
- [`layervalues2pixel()`](https://reginalexavier.github.io/wcswatin/dev/reference/layervalues2pixel.md):
  Extract time series for each grid cell
- [`cube2table()`](https://reginalexavier.github.io/wcswatin/dev/reference/cube2table.md):
  Convert raster data cube to tabular format
- [`daily_aggregation()`](https://reginalexavier.github.io/wcswatin/dev/reference/daily_aggregation.md):
  Aggregate raster data to daily time steps
- [`tbl_from_references()`](https://reginalexavier.github.io/wcswatin/dev/reference/tbl_from_references.md):
  Extract raster values at reference points

### Station Data Processing

- [`point_to_daily()`](https://reginalexavier.github.io/wcswatin/dev/reference/point_to_daily.md):
  Import and organize daily station data
- [`files_to_table()`](https://reginalexavier.github.io/wcswatin/dev/reference/files_to_table.md):
  Consolidate multiple station files into a single table
- [`table_to_files()`](https://reginalexavier.github.io/wcswatin/dev/reference/table_to_files.md):
  Split consolidated data back into individual files
- [`fill_gap()`](https://reginalexavier.github.io/wcswatin/dev/reference/fill_gap.md):
  Fill missing data using correlation methods
- [`ts_to_point()`](https://reginalexavier.github.io/wcswatin/dev/reference/ts_to_point.md):
  Trend surface interpolation to specific points (watershed centroids)
- [`ts_to_area()`](https://reginalexavier.github.io/wcswatin/dev/reference/ts_to_area.md):
  Trend surface interpolation to create continuous raster surfaces
- [`save_daily_tbl()`](https://reginalexavier.github.io/wcswatin/dev/reference/save_daily_tbl.md):
  Save daily tables in SWAT format

### SWAT-Specific Functions

- [`var_main_creator()`](https://reginalexavier.github.io/wcswatin/dev/reference/var_main_creator.md):
  Generate SWAT input metadata tables
- [`main_input_var()`](https://reginalexavier.github.io/wcswatin/dev/reference/main_input_var.md):
  Create main variable input tables for SWAT
- [`rh_calculator()`](https://reginalexavier.github.io/wcswatin/dev/reference/rh_calculator.md):
  Calculate relative humidity from other variables
- [`windspeed_calculator()`](https://reginalexavier.github.io/wcswatin/dev/reference/windspeed_calculator.md):
  Calculate wind speed from components

### Data Analysis & Utilities

- [`count_na()`](https://reginalexavier.github.io/wcswatin/dev/reference/count_na.md):
  Check data completeness and missing values
- [`summary_table()`](https://reginalexavier.github.io/wcswatin/dev/reference/summary_table.md):
  Generate statistical summaries
- [`summary_plot()`](https://reginalexavier.github.io/wcswatin/dev/reference/summary_plot.md):
  Visualize data distributions
- [`unit_converter()`](https://reginalexavier.github.io/wcswatin/dev/reference/unit_converter.md):
  Convert between measurement units

## Data Requirements

The package works with spatial data in **WGS 84** geographic coordinate
system (EPSG:4326), which is the standard format for most climate
datasets.

### Supported Data Sources

- **Climate Reanalysis**: ERA5-Land, MERRA-2, NCEP
- **Satellite Precipitation**: GPM IMERG, PERSIANN, CHIRPS
- **Station Data**: Standard SWAT weather file format

## Documentation

- **Vignettes**: Detailed tutorials and workflows
- **Function Reference**: `?function_name` or visit package
  documentation
- **Examples**: Run `example(function_name)` for usage examples

## Getting Help

- **Bug Reports**: [GitHub
  Issues](https://github.com/reginalexavier/wcswatin/issues)
- **Contact**:
  - Réginal Exavier: <reginalexavier@rocketmail.com>
  - Peter Zeilhofer: <zeilhoferpeter@gmail.com>

## Citation

If you use wcswatin in your research, please cite:

``` R
@software{wcswatin2025,
  author = {Exavier, Reginal and Zeilhofer, Peter},
  title = {wcswatin: Weather & Climate SWAT Input},
  year = {2025},
  url = {https://github.com/reginalexavier/wcswatin}
}
```

## License

GPL (\>= 3)

## Acknowledgments

This project is funded by the [Critical Ecosystem Partnership Fund
(CEPF)](https://www.cepf.net/).
