# Preparing weather and climate inputs with wcswatin

`wcswatin` prepares weather and climate data for workflows that need
SWAT-ready inputs. This vignette uses the small files shipped in
`inst/extdata` to show the main object shapes and processing steps. The
pkgdown site includes longer articles with a production-size ERA5-Land
case study.

``` r

library(wcswatin)
```

## Example data

``` r

daily_nc <- system.file(
  "extdata/nc_data/daily_2m_temperature_daily_maximum_2025.nc",
  package = "wcswatin"
)

hourly_nc <- system.file(
  "extdata/nc_data/hourly_2m_temperature_2days_2025.nc",
  package = "wcswatin"
)

multi_nc <- system.file(
  "extdata/nc_data/hourly_multi_2days_2025.nc",
  package = "wcswatin"
)

stations_file <- system.file(
  "extdata/pcp_stations/pcp.txt",
  package = "wcswatin"
)

basin_file <- system.file(
  "extdata/sl_bassin/sl_bassin_limit.shp",
  package = "wcswatin"
)

basename(c(daily_nc, hourly_nc, multi_nc, stations_file, basin_file))
#> [1] "daily_2m_temperature_daily_maximum_2025.nc"
#> [2] "hourly_2m_temperature_2days_2025.nc"       
#> [3] "hourly_multi_2days_2025.nc"                
#> [4] "pcp.txt"                                   
#> [5] "sl_bassin_limit.shp"
```

## Inspect and load inputs

[`raster_info()`](https://reginalexavier.github.io/wcswatin/dev/reference/raster_info.md)
summarizes the variables, units, time range, spatial extent, and
dimensions of a raster file. This is usually the first check after
downloading or receiving a NetCDF file, because `n_layers`,
`time_start`, `time_end`, and `time_resolution` determine whether the
next step starts from daily layers or from an hourly workflow.
[`var_names()`](https://reginalexavier.github.io/wcswatin/dev/reference/var_names.md)
returns just the data variable names.

``` r

raster_info(c(daily_nc, hourly_nc, multi_nc))
#>                                          file variable
#>                                        <char>   <char>
#> 1: daily_2m_temperature_daily_maximum_2025.nc      t2m
#> 2:        hourly_2m_temperature_2days_2025.nc      t2m
#> 3:                 hourly_multi_2days_2025.nc      d2m
#> 4:                 hourly_multi_2days_2025.nc      t2m
#> 5:                 hourly_multi_2days_2025.nc     ssrd
#> 6:                 hourly_multi_2days_2025.nc      u10
#> 7:                 hourly_multi_2days_2025.nc      v10
#> 8:                 hourly_multi_2days_2025.nc       tp
#>                                         long_name    unit n_layers n_rows
#>                                            <char>  <char>    <int>  <num>
#> 1:                            2 metre temperature       K        5     19
#> 2:                            2 metre temperature       K       48     19
#> 3:                   2 metre dewpoint temperature       K       48     19
#> 4:                            2 metre temperature       K       48     19
#> 5: Surface short-wave (solar) radiation downwards J m**-2       48     19
#> 6:                      10 metre U wind component m s**-1       48     19
#> 7:                      10 metre V wind component m s**-1       48     19
#> 8:                            Total precipitation       m       48     19
#>    n_cols  x_min  x_max  y_min  y_max                        crs has_time
#>     <num>  <num>  <num>  <num>  <num>                     <char>   <lgcl>
#> 1:     28 -55.95 -53.15 -17.25 -15.35 WGS 84 (CRS84) (OGC:CRS84)     TRUE
#> 2:     28 -55.95 -53.15 -17.25 -15.35 WGS 84 (CRS84) (OGC:CRS84)     TRUE
#> 3:     28 -55.95 -53.15 -17.25 -15.35 WGS 84 (CRS84) (OGC:CRS84)     TRUE
#> 4:     28 -55.95 -53.15 -17.25 -15.35 WGS 84 (CRS84) (OGC:CRS84)     TRUE
#> 5:     28 -55.95 -53.15 -17.25 -15.35 WGS 84 (CRS84) (OGC:CRS84)     TRUE
#> 6:     28 -55.95 -53.15 -17.25 -15.35 WGS 84 (CRS84) (OGC:CRS84)     TRUE
#> 7:     28 -55.95 -53.15 -17.25 -15.35 WGS 84 (CRS84) (OGC:CRS84)     TRUE
#> 8:     28 -55.95 -53.15 -17.25 -15.35 WGS 84 (CRS84) (OGC:CRS84)     TRUE
#>    time_start            time_end time_step time_resolution
#>        <char>              <char>    <char>          <char>
#> 1: 2025-10-01          2025-10-05      days          1 days
#> 2: 2025-10-01 2025-10-02 23:00:00     hours         1 hours
#> 3: 2025-10-01 2025-10-02 23:00:00     hours         1 hours
#> 4: 2025-10-01 2025-10-02 23:00:00     hours         1 hours
#> 5: 2025-10-01 2025-10-02 23:00:00     hours         1 hours
#> 6: 2025-10-01 2025-10-02 23:00:00     hours         1 hours
#> 7: 2025-10-01 2025-10-02 23:00:00     hours         1 hours
#> 8: 2025-10-01 2025-10-02 23:00:00     hours         1 hours
var_names(multi_nc)
#>    d2m    t2m   ssrd    u10    v10     tp 
#>  "d2m"  "t2m" "ssrd"  "u10"  "v10"   "tp"
```

The package input helpers normalize common file and object types.

``` r

daily_cube <- input_raster(daily_nc)
stations <- input_table(stations_file)
basin <- input_vector(basin_file)

daily_cube
#> class       : SpatRaster
#> size        : 19, 28, 5  (nrow, ncol, nlyr)
#> dimensions  : longitude, latitude, valid_time (28, 19, 5}
#> resolution  : 0.1, 0.1  (x, y)
#> extent      : -55.95, -53.15, -17.25, -15.35  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84 (CRS84) (OGC:CRS84)
#> source      : daily_2m_temperature_daily_maximum_2025.nc
#> varname     : t2m (2 metre temperature)
#> names       : t2m_1, t2m_2, t2m_3, t2m_4, t2m_5
#> unit        : K
#> time (days) : 2025-10-01 to 2025-10-05 (5 steps)
head(stations)
#>       ID      NAME     LAT     LON ELEVATION
#>    <int>    <char>   <num>   <num>     <num>
#> 1:     1 p-1553003 -15.940 -53.450       597
#> 2:     2 p-1554006 -15.989 -54.968       256
#> 3:     3 p-1555005 -15.840 -55.320       783
#> 4:     4 p-1556007 -15.699 -55.136       699
#> 5:     5 p-1653002 -16.350 -53.760       482
#> 6:     6 p-1653004 -16.940 -53.530       735
basin
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 1, 2  (geometries, attributes)
#> extent      : -55.4031, -53.70666, -17.17436, -15.47456  (xmin, xmax, ymin, ymax)
#> source      : sl_bassin_limit.shp
#> coord. ref. : lon/lat WGS 84 (EPSG:4326)
#> names       : OBJECTID  Area
#> type        :    <num> <num>
#> values      :        1 12372
```

## Extract raster values at reference points

[`tbl_from_references()`](https://reginalexavier.github.io/wcswatin/dev/reference/tbl_from_references.md)
extracts gridded values at reference point locations. The points can be
a table path, a `data.frame`, an `sf` object, a `SpatVector`, or a
vector file accepted by
[`input_vector()`](https://reginalexavier.github.io/wcswatin/dev/reference/input_vector.md).

``` r

station_values <- tbl_from_references(
  raster_file = daily_cube,
  ref_points = stations_file,
  prefix_colname = "t2m"
)

dim(station_values)
#> [1]  5 14
station_values[, 1:4]
#>   t2m_p-1553003 t2m_p-1554006 t2m_p-1555005 t2m_p-1556007
#> 1      310.3444      309.4166      305.6393      308.0358
#> 2      308.7540      308.6392      305.9478      307.2212
#> 3      308.6163      307.7622      304.8813      306.4009
#> 4      309.5529      310.1583      306.7990      308.4806
#> 5      309.4852      311.2538      307.5175      309.0233
```

The result has one row per raster layer and one column per reference
point. This shape is useful for comparing gridded products with station
records after the time steps have been aligned.

## Aggregate hourly files to daily files

[`daily_aggregation()`](https://reginalexavier.github.io/wcswatin/dev/reference/daily_aggregation.md)
works on folders of SWAT-style time-series files. The example below
creates one hourly table and aggregates it to two daily values.

``` r

hourly_folder <- file.path(tempdir(), "wcswatin_hourly")
daily_folder <- file.path(tempdir(), "wcswatin_daily")
dir.create(hourly_folder, showWarnings = FALSE)

hourly_values <- data.frame(t2m = seq(280, 303, length.out = 48))
utils::write.table(
  hourly_values,
  file.path(hourly_folder, "t2m_20251001.txt"),
  row.names = FALSE,
  sep = ","
)

daily_aggregation(
  folder_in = hourly_folder,
  folder_out = daily_folder,
  from = "2025-10-01 00",
  to = "2025-10-02 23",
  drop_first_record = FALSE,
  aggregation_function = mean
)
#>   |                                                                              |                                                                      |   0%  |                                                                              |======================================================================| 100%

input_table(file.path(daily_folder, "t2m_20251001.txt"))
#>         t2m
#>       <num>
#> 1: 285.6277
#> 2: 297.3723
```

For accumulated variables timestamped at the end of the accumulation
period, use `mode = "value_at_hour"`. For ERA5-Land-style daily
accumulated values stored at `00:00`, keep `value_hour = 0` and include
the closing `00:00` record in the input period.

``` r

accumulated_folder <- file.path(tempdir(), "wcswatin_accumulated")
dir.create(accumulated_folder, showWarnings = FALSE)

accumulated_values <- data.frame(tp = seq_len(24))
utils::write.table(
  accumulated_values,
  file.path(accumulated_folder, "tp_20251001.txt"),
  row.names = FALSE,
  sep = ","
)

value_hour_folder <- file.path(tempdir(), "wcswatin_value_hour")

daily_aggregation(
  folder_in = accumulated_folder,
  folder_out = value_hour_folder,
  from = "2025-10-01 01",
  to = "2025-10-02 00",
  drop_first_record = FALSE,
  mode = "value_at_hour",
  value_hour = 0
)
#>   |                                                                              |                                                                      |   0%  |                                                                              |======================================================================| 100%

input_table(file.path(value_hour_folder, "tp_20251001.txt"))
#>       tp
#>    <int>
#> 1:    24
```

## Station tables

Station files can be consolidated into one table for quality checks and
simple summaries.

``` r

station_folder <- system.file("extdata/pcp_stations", package = "wcswatin")

pcp_table <- files_to_table(
  files_path = station_folder,
  files_pattern = "^p-",
  start_date = "2002-01-01",
  end_date = "2002-01-31",
  na_value = -99,
  neg_to_zero = TRUE
)

pcp_table[1:5, 1:5]
#>         date p-1553003 p-1554006 p-1555005 p-1556007
#> 1 2002-01-01         0       8.4         0       0.0
#> 2 2002-01-02        NA      12.3         0       0.0
#> 3 2002-01-03         0       0.0         0      30.4
#> 4 2002-01-04         0       5.1         0      38.6
#> 5 2002-01-05         0       0.0        NA       0.0
count_na(pcp_table, percent = TRUE)[1:5, ]
#>      column  Prop_NA
#> 1      date  0.00000
#> 2 p-1553003 22.58065
#> 3 p-1554006 12.90323
#> 4 p-1555005 12.90323
#> 5 p-1556007 16.12903
```

The inverse operation writes each station column back to a separate
file.

``` r

station_out <- file.path(tempdir(), "wcswatin_station_files")

table_to_files(
  table = pcp_table[, -1],
  folder_path = station_out,
  first_date = "20020101",
  file_extension = "txt"
)

head(list.files(station_out))
#> [1] "p-1553003.txt" "p-1554006.txt" "p-1555005.txt" "p-1556007.txt"
#> [5] "p-1653002.txt" "p-1653004.txt"
```

[`point_to_daily()`](https://reginalexavier.github.io/wcswatin/dev/reference/point_to_daily.md)
reorganizes station observations into one table per day. It is commonly
used before spatial interpolation from stations.

``` r

daily_tables <- point_to_daily(
  my_folder = station_folder,
  start_date = "20020101",
  end_date = "20020131"
)

save_daily_tbl(
  tbl_list = daily_tables,
  path = file.path(tempdir(), "wcswatin_daily_station_tables")
)
```

## Variable derivation

The package also includes helpers for deriving SWAT weather variables:

- [`unit_converter()`](https://reginalexavier.github.io/wcswatin/dev/reference/unit_converter.md)
  applies a transformation to all values in matching files;
- [`rh_calculator()`](https://reginalexavier.github.io/wcswatin/dev/reference/rh_calculator.md)
  derives relative humidity from dewpoint and air temperature;
- [`windspeed_calculator()`](https://reginalexavier.github.io/wcswatin/dev/reference/windspeed_calculator.md)
  derives wind speed from wind components.

For example, a Kelvin-to-Celsius conversion can be applied to a folder
of files.

``` r

celsius_folder <- file.path(tempdir(), "wcswatin_celsius")

unit_converter(
  folder_in = daily_folder,
  folder_out = celsius_folder,
  FUN = function(x) x - 273.15
)
#>   |                                                                              |                                                                      |   0%  |                                                                              |======================================================================| 100%

input_table(file.path(celsius_folder, "t2m_20251001.txt"))
#>         t2m
#>       <num>
#> 1: 12.47766
#> 2: 24.22234
```

## Next steps

The examples above cover the core data path with compact files. For a
realistic case study, see the pkgdown articles:

- “ERA5-Land hourly data to SWAT inputs”;
- “Station interpolation workflow”;
- “Running a similar case study”.
