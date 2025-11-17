# Convert a Cube format data into a Table format

The function extracts the values of a NetCDF/raster layer and converts
it to a table format containing the values of the pixels and the layer
name as two columns. The pixel is identified by the ID `(row and col)`,
and the layer name represents the date of the data collected. All layers
are stacked in a single table, each layer is differentiated by the
column layer_name containing the date of the data collected. The
function, due to the large amount of data, counts with the structure of
parallel processing based on the future package to speed up the process.
By default, the computation is done in sequential mode
`future::plan(future::sequential)`, for parallel processing, the user
must change to the desired mode (ex: future::plan(future::multisession,
workers = 6)).

## Usage

``` r
cube2table(
  input_path,
  var = NA,
  n_layers,
  study_area,
  future_scheduling = 1,
  missing_value = -99,
  final_dir = NULL,
  side_effect = "only",
  temp_dir = NULL,
  clean_after = FALSE
)
```

## Arguments

- input_path:

  Path to the NetCDF or raster file.

- var:

  The variable to be extracted. The default is NA. For NetCDF files
  containing multiple variables, the user must provide the name of the
  variable to be extracted. If the file contains only one variable, the
  user can leave this argument as NA.

- n_layers:

  Number of layers in the raster file to be extracted

- study_area:

  The table from 'study_area_records'

- future_scheduling:

  Controling how the future will be scheduled and distributed between
  the workers. The default is 1, which means that the future will be
  scheduled by core. See the documentation of future package for more
  details
  [`future.apply::future_lapply()`](https://future.apply.futureverse.org/reference/future_lapply.html).

- missing_value:

  The value to be used when the data is missing

- final_dir:

  The directory to save the final table. If NULL, the final table will
  not be saved.

- side_effect:

  The side effect of the function. The default is "only", which means
  that the function will only save the final table in disk (if final_dir
  is provided). The other options are "both" and "none". If "both", the
  function will save the final table in disk and return it within the R
  environment. If "none", the function will only return the final table
  whithin the R environment.

- temp_dir:

  The directory to save the intermediate tables. If the directory
  already exists, the tables will be saved in the existing directory. If
  the directory does not exist, it will be created. If NULL, the tables
  will be saved in a temporary directory.

- clean_after:

  Logical. If TRUE, the directory with the intermediate tables will be
  deleted after the process is finished. If FALSE, the directory will be
  kept. The default is FALSE. And when the temp_dir is NULL, what
  implies that the tables will be saved in a temporary directory, the
  temp_dir will be deleted after the process is finished.

## Value

A table containing the:

- ID: The pixel ID (row and col);

- values: The values of the pixel;

- layer_name: The layer name (date of the data collected).
