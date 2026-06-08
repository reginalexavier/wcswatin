#' Shows raster variables present in a NetCDF
#'
#' @param path Path where the netcdf file is located
#'
#' @return Character vector of raster variable names
#' @export
#'
var_names <- function(path) {
  lapply(path, function(x) {
    if (!file.exists(x)) {
      stop("File does not exist: ", x)
    }

    nc_file <- ncdf4::nc_open(x)
    on.exit(ncdf4::nc_close(nc_file))

    spatial_vars <- Filter(nc_var_has_spatial_dims, nc_file$var)
    vapply(spatial_vars, `[[`, character(1), "name")
  }) |>
    unlist()
}

#' Summarize raster file metadata
#'
#' @param path Path to one or more raster files.
#'
#' @return A data.table with one row per raster variable and the columns:
#'   file, variable, long_name, unit, n_layers, n_rows, n_cols, x_min, x_max,
#'   y_min, y_max, crs, has_time, time_start, time_end, time_step and
#'   time_resolution. The file and CRS columns are short labels intended for
#'   console inspection.
#' @export
#'
raster_info <- function(path) {
  if (!is.character(path) || length(path) == 0 || any(is.na(path))) {
    stop("The argument 'path' must be a character vector of file paths.")
  }

  data.table::rbindlist(
    lapply(path, raster_info_one),
    fill = TRUE
  )
}

raster_info_one <- function(path) {
  if (!file.exists(path)) {
    stop("File does not exist: ", path)
  }

  raster_obj <- input_raster(path)
  extension <- tolower(tools::file_ext(path))

  if (extension %in% c("nc", "nc4")) {
    nc_raster_info(path, raster_obj)
  } else {
    generic_raster_info(path, raster_obj)
  }
}

generic_raster_info <- function(path, raster_obj) {
  data.table::data.table(
    file = basename(path),
    variable = tools::file_path_sans_ext(basename(path)),
    long_name = NA_character_,
    unit = NA_character_,
    n_layers = terra::nlyr(raster_obj),
    n_rows = terra::nrow(raster_obj),
    n_cols = terra::ncol(raster_obj),
    x_min = terra::xmin(raster_obj),
    x_max = terra::xmax(raster_obj),
    y_min = terra::ymin(raster_obj),
    y_max = terra::ymax(raster_obj),
    crs = raster_crs_label(raster_obj),
    has_time = has_raster_time(raster_obj),
    time_start = raster_time_start(raster_obj),
    time_end = raster_time_end(raster_obj),
    time_step = raster_time_step(raster_obj),
    time_resolution = raster_time_resolution(raster_obj)
  )
}

nc_raster_info <- function(path, raster_obj) {
  nc_file <- ncdf4::nc_open(path)
  on.exit(ncdf4::nc_close(nc_file))

  spatial_vars <- Filter(nc_var_has_spatial_dims, nc_file$var)

  if (length(spatial_vars) == 0) {
    return(generic_raster_info(path, raster_obj))
  }

  data.table::rbindlist(
    lapply(spatial_vars, function(variable) {
      data.table::data.table(
        file = basename(path),
        variable = variable$name,
        long_name = empty_to_na(variable$longname),
        unit = empty_to_na(variable$units),
        n_layers = nc_var_layer_count(variable),
        n_rows = terra::nrow(raster_obj),
        n_cols = terra::ncol(raster_obj),
        x_min = terra::xmin(raster_obj),
        x_max = terra::xmax(raster_obj),
        y_min = terra::ymin(raster_obj),
        y_max = terra::ymax(raster_obj),
        crs = raster_crs_label(raster_obj),
        has_time = nc_var_has_time_dim(variable),
        time_start = raster_time_start(raster_obj),
        time_end = raster_time_end(raster_obj),
        time_step = raster_time_step(raster_obj),
        time_resolution = raster_time_resolution(raster_obj)
      )
    }),
    fill = TRUE
  )
}

nc_var_has_spatial_dims <- function(variable) {
  dim_names <- nc_var_dim_names(variable)
  # NetCDF files can include auxiliary variables such as number or expver.
  # Only variables with horizontal spatial dimensions are raster variables.
  any(dim_names %in% c("x", "lon", "longitude")) &&
    any(dim_names %in% c("y", "lat", "latitude"))
}

nc_var_has_time_dim <- function(variable) {
  any(nc_var_dim_names(variable) %in% c("time", "valid_time"))
}

nc_var_layer_count <- function(variable) {
  dim_names <- nc_var_dim_names(variable)
  dim_lengths <- vapply(variable$dim, `[[`, integer(1), "len")
  non_spatial <- !dim_names %in%
    c(
      "x",
      "y",
      "lon",
      "lat",
      "longitude",
      "latitude"
    )

  if (!any(non_spatial)) {
    return(1L)
  }

  as.integer(prod(dim_lengths[non_spatial]))
}

nc_var_dim_names <- function(variable) {
  tolower(vapply(variable$dim, `[[`, character(1), "name"))
}

has_raster_time <- function(raster_obj) {
  !all(is.na(terra::time(raster_obj)))
}

raster_time_start <- function(raster_obj) {
  if (!has_raster_time(raster_obj)) {
    return(NA_character_)
  }

  as.character(min(unique(terra::time(raster_obj)), na.rm = TRUE))
}

raster_time_end <- function(raster_obj) {
  if (!has_raster_time(raster_obj)) {
    return(NA_character_)
  }

  as.character(max(unique(terra::time(raster_obj)), na.rm = TRUE))
}

raster_time_step <- function(raster_obj) {
  if (!has_raster_time(raster_obj)) {
    return(NA_character_)
  }

  raster_time <- unique(terra::time(raster_obj))

  if (length(raster_time) < 2 || all(is.na(raster_time))) {
    return(terra::timeInfo(raster_obj)$step)
  }

  attr(diff(sort(raster_time)), "units")
}

raster_time_resolution <- function(raster_obj) {
  raster_time <- unique(terra::time(raster_obj))

  if (length(raster_time) < 2 || all(is.na(raster_time))) {
    return(NA_character_)
  }

  # Use the median interval so regular time series return compact labels such
  # as "1 days" or "1 hours".
  time_diff <- diff(sort(raster_time))
  paste(
    as.numeric(stats::median(time_diff)),
    attr(time_diff, "units")
  )
}

raster_crs_label <- function(raster_obj) {
  # terra::crs() returns full WKT by default; describe = TRUE gives a short
  # label that is much easier to inspect in a tabular console summary.
  crs_description <- tryCatch(
    terra::crs(raster_obj, describe = TRUE),
    error = function(error) NULL
  )

  if (is.null(crs_description) || nrow(crs_description) == 0) {
    return(NA_character_)
  }

  crs_name <- empty_to_na(crs_description$name[1])
  crs_authority <- empty_to_na(crs_description$authority[1])
  crs_code <- empty_to_na(crs_description$code[1])

  if (is.na(crs_name)) {
    return(NA_character_)
  }

  if (!is.na(crs_authority) && !is.na(crs_code)) {
    return(as.character(glue::glue("{crs_name} ({crs_authority}:{crs_code})")))
  }

  crs_name
}

empty_to_na <- function(x) {
  if (length(x) == 0 || is.na(x) || x == "") {
    return(NA_character_)
  }

  x
}
