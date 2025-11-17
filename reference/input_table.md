# Input Table

Method to load a table file and convert it into a data.table object.

## Usage

``` r
input_table(x, ...)

# S4 method for class 'character'
input_table(x, ...)

# S4 method for class 'data.table'
input_table(x, ...)

# S4 method for class 'data.frame'
input_table(x, ...)
```

## Arguments

- x:

  path (character) to the file or a data.table object.

- ...:

  additional arguments to
  [`data.table::fread`](https://rdatatable.gitlab.io/data.table/reference/fread.html).

## Value

data.table

## See also

[`data.table::fread`](https://rdatatable.gitlab.io/data.table/reference/fread.html)
