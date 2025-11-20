# Export tables to `txt` or `csv` files

Export tables to `txt` or `csv` files

## Usage

``` r
table_to_files(table, folder_path, first_date, file_extension = "txt")
```

## Arguments

- table:

  A table `data.frame` containing all the observations

- folder_path:

  Character string of the folder where the file must be saved.

- first_date:

  Character string of the first date for the time series. This value is
  used to renaming the columns on every single file while saving. The
  actual name is used as the file names. The suggested format is
  `%y%m%d`

- file_extension:

  Character. `txt` or `csv`.
