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

## Value

No return value (`NULL`), called for side effects. Writes one
single-column `txt` or `csv` file per column in `table` to
`folder_path`. Each file is named after its input column and uses
`first_date` as its column name.
