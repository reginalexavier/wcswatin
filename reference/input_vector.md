# Input Vector

Method to load a vector file and convert it into a SpatVector object.

## Usage

``` r
input_vector(x, ...)

# S4 method for class 'character'
input_vector(x, ...)

# S4 method for class 'SpatVector'
input_vector(x, ...)

# S4 method for class 'sf'
input_vector(x, ...)
```

## Arguments

- x:

  path (character) to the file or a SpatVector object.

- ...:

  additional arguments to
  `terra::`[`vect`](https://rspatial.github.io/terra/reference/vect.html).

## Value

SpatVector

## See also

[`terra::vect`](https://rspatial.github.io/terra/reference/vect.html)
