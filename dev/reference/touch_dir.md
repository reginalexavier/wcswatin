# Create a directory if it does not exist

This function creates a directory if it does not exist. It is an
internal function used in the `unit_converter` function.

## Usage

``` r
touch_dir(folder_path, return_path = FALSE)
```

## Arguments

- folder_path:

  A character string with the path of the directory to be created.

- return_path:

  logical. If `TRUE`, the function returns the path

## Value

NULL. Only for side effects.
