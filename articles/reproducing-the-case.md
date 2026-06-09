# Running a similar case study

This article describes how to structure a similar `wcswatin` project
with your own data. The São Lourenço basin area in Mato Grosso, Brazil,
is used in the package website as a test region, but the same workflow
applies to any basin or region of interest with compatible raster,
vector, and station inputs.

## Data source

The gridded part of the case uses ERA5-Land hourly data for 2025-10-01
to 2025-12-31.

| Variable | ERA5-Land name                    | Original unit | SWAT unit |
|----------|-----------------------------------|---------------|-----------|
| `u10`    | 10m u component of wind           | m s^-1        | m s^-1    |
| `v10`    | 10m v component of wind           | m s^-1        | m s^-1    |
| `d2m`    | 2m dewpoint temperature           | K             | deg C     |
| `t2m`    | 2m temperature                    | K             | deg C     |
| `ssrd`   | surface solar radiation downwards | J m^-2        | MJ m^-2   |
| `tp`     | total precipitation               | m             | mm        |
| `ws10`   | wind speed                        | derived       | m s^-1    |
| `rh2m`   | relative humidity                 | derived       | %         |

The NetCDF files can be downloaded with any CDS workflow. The companion
`cds-downloader` CLI is optional and can help create repeatable download
requests:

``` bash
cds-downloader --help
```

Tool page: <https://github.com/reginalexavier/cds-downloader>

## Suggested directory layout

Keep raw inputs, intermediate outputs, and final SWAT-ready files in
explicit project folders. One simple pattern is:

``` r

Sys.setenv(WCSWATIN_CASE_ROOT = "/path/to/your_case")
case_root <- Sys.getenv("WCSWATIN_CASE_ROOT")
```

``` text
data/
  input/
    nc_files/
      hourly/
      daily/
    raster/
    weather-station-data/
  output/
```

In the São Lourenço test run, the input files were about 94 MB and the
complete output folder was about 193 MB with intermediates. The final
daily SWAT-style gridded outputs were much smaller, around 200-381 KB
per variable.

## Choose the time resolution

Start by inspecting the NetCDF metadata.
[`raster_info()`](https://reginalexavier.github.io/wcswatin/reference/raster_info.md)
shows the data variables, units, layer count, date range, and time
resolution, which are the main details needed to choose the processing
route.

``` r

raster_info(file.path(case_root, "data/input/nc_files/hourly/t2m.nc"))
raster_info(file.path(case_root, "data/input/nc_files/daily/t2m_daily.nc"))
```

There are three practical starting points:

| Starting point | Main path | Consequence |
|----|----|----|
| Hourly NetCDF | [`cube2table()`](https://reginalexavier.github.io/wcswatin/reference/cube2table.md) -\> [`layervalues2pixel()`](https://reginalexavier.github.io/wcswatin/reference/layervalues2pixel.md) -\> [`daily_aggregation()`](https://reginalexavier.github.io/wcswatin/reference/daily_aggregation.md) | Full control over daily statistics and timestamp rules |
| Daily NetCDF from CDS or `cds-downloader` | [`cube2table()`](https://reginalexavier.github.io/wcswatin/reference/cube2table.md) -\> [`layervalues2pixel()`](https://reginalexavier.github.io/wcswatin/reference/layervalues2pixel.md) | Faster extraction and no table aggregation step |
| Hourly NetCDF reduced locally | [`datacube_aggregation()`](https://reginalexavier.github.io/wcswatin/reference/datacube_aggregation.md) -\> [`cube2table()`](https://reginalexavier.github.io/wcswatin/reference/cube2table.md) -\> [`layervalues2pixel()`](https://reginalexavier.github.io/wcswatin/reference/layervalues2pixel.md) | Faster extraction after daily aggregation or value-at-hour selection |

For accumulated variables timestamped at a specific hour,
`datacube_aggregation(mode = "value_at_hour")` can reduce the hourly
cube before extraction. For ERA5-Land accumulated values timestamped at
`00:00`, use `value_hour = 0` and `date_shift_days = -1`; set
`drop_first_layer = TRUE` only when the first selected layer belongs to
the day before the requested period.

## Workflow checklist

The case workflow can be implemented with ordinary R scripts or
notebooks. The important part is the order of operations:

| Step | Main functions | Purpose |
|---:|----|----|
| 1 | [`study_area_records()`](https://reginalexavier.github.io/wcswatin/reference/study_area_records.md) | Build `study_area.csv` from raster grid, basin, and DEM |
| 2 | [`main_input_var()`](https://reginalexavier.github.io/wcswatin/reference/main_input_var.md) | Create one `mainFile.csv` per variable |
| 3 | [`cube2table()`](https://reginalexavier.github.io/wcswatin/reference/cube2table.md) | Extract NetCDF cubes into long layer tables |
| 4 | [`layervalues2pixel()`](https://reginalexavier.github.io/wcswatin/reference/layervalues2pixel.md) | Write one hourly time series per pixel |
| 5 | [`unit_converter()`](https://reginalexavier.github.io/wcswatin/reference/unit_converter.md), [`daily_aggregation()`](https://reginalexavier.github.io/wcswatin/reference/daily_aggregation.md) | Convert units and aggregate hourly files to daily files |
| 6 | [`windspeed_calculator()`](https://reginalexavier.github.io/wcswatin/reference/windspeed_calculator.md), [`rh_calculator()`](https://reginalexavier.github.io/wcswatin/reference/rh_calculator.md) | Derive wind speed and relative humidity |
| 7 | [`files_to_table()`](https://reginalexavier.github.io/wcswatin/reference/files_to_table.md), [`fill_gap()`](https://reginalexavier.github.io/wcswatin/reference/fill_gap.md), [`point_to_daily()`](https://reginalexavier.github.io/wcswatin/reference/point_to_daily.md) | Prepare station observations for interpolation |
| 8 | [`ts_to_area()`](https://reginalexavier.github.io/wcswatin/reference/ts_to_area.md), [`ts_to_point()`](https://reginalexavier.github.io/wcswatin/reference/ts_to_point.md), [`ts_point_to_files()`](https://reginalexavier.github.io/wcswatin/reference/ts_point_to_files.md) | Interpolate station values to rasters or target points |
| 9 | [`tbl_from_references()`](https://reginalexavier.github.io/wcswatin/reference/tbl_from_references.md) | Prepare extracted raster tables for validation workflows |

## Parallel extraction

[`cube2table()`](https://reginalexavier.github.io/wcswatin/reference/cube2table.md)
is the part of the workflow where parallel execution usually pays off
the most, because the extraction work can be split by raster layer. The
function follows the `future` model: users select the backend with
[`future::plan()`](https://future.futureverse.org/reference/plan.html),
and the extraction call itself does not need to change.

``` r

# Debug or reproduce in one R process
future::plan(future::sequential)

# Portable local parallelism
future::plan("multisession", workers = 8)

# Unix-like terminal sessions
future::plan("multicore", workers = 8)
```

In the benchmarked run with 2,208 layers and 229 grid cells:

| Mode         | Workers |  Time per variable |
|--------------|--------:|-------------------:|
| multicore    |      10 |  about 6.6 minutes |
| multicore    |       8 |  about 7.0 minutes |
| multisession |      10 |  about 7.0 minutes |
| multisession |       8 |  about 7.1 minutes |
| sequential   |       1 | about 39.5 minutes |

This keeps `wcswatin` from hard-coding a parallel backend. A local
workstation, an RStudio session, a server, or a scheduler-backed setup
can use the same workflow with the `future` backend that fits that
environment. See the `future` overview for backend details:
<https://cran.r-project.org/web/packages/future/vignettes/future-1-overview.html>.

## Adapting the case

For a new region, replace the basin boundary, DEM, station metadata, and
NetCDF files, then keep the same processing order. The exact variable
list and daily aggregation mode should follow the source product
semantics. For accumulated ERA5-Land variables, values timestamped at
`00:00` represent the previous day, so use `mode = "value_at_hour"` with
`value_hour = 0` after selecting an input period that includes the
closing midnight records.
