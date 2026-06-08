#' Create a daily aggregation from an hourly datacube
#'
#'
#' `datacube_aggregation()` aggregates a datacube by a given function. The
#' function can either apply an aggregation function to each day of the datacube
#' or select the layer timestamped at a given hour.
#'
#' @param input_path Path to the datasetcube
#' @param output_filename Path to the output file
#' @param fun Function to be applied to the datasetcube (default is mean). The
#'  function must be a function that takes a vector as input and returns a
#'  single value. The main functions to be used are: Sum, Mean, Min, Max, First
#'  and Last. For last, use `dplyr::last`. To use customized function say, for
#'  example "min", you could use use the format fun = \(x) min(x).
#'  See [terra::tapp()] for more information.
#' @param cores Number of cores to use for the aggregation. Default is 1. See
#'  [terra::tapp()] for more information.
#'  See [terra::tapp()] for more information.
#' @param mode The mode of aggregation. The options are \code{agg_fun} or
#'   \code{value_at_hour}. The \code{agg_fun} mode applies \code{fun} to all
#'   layers in each day. The \code{value_at_hour} mode returns the layer
#'   timestamped at \code{value_hour}.
#' @param value_hour Integer hour between 0 and 23 used when
#'   \code{mode = "value_at_hour"}. The default is 0, which matches products
#'   whose daily accumulated value is timestamped at 00:00 at the end of the
#'   accumulation period.
#' @param date_shift_days Whole number of days added to the output layer dates
#'   when \code{mode = "value_at_hour"}. Use \code{-1} for products whose
#'   00:00 timestamp represents the previous day.
#' @param drop_first_layer Logical. If TRUE and
#'   \code{mode = "value_at_hour"}, the first selected layer is removed. This is
#'   useful when the first selected layer represents the day before the
#'   requested period.
#' @param ... Additional arguments to pass to [names_to_date()]
#'
#' @return A raster object with the aggregated data
#'
#' @export
#'
#' @seealso [terra::tapp()], [names_to_date()], [ERA5 family post-processed daily statistics documentation](https://confluence.ecmwf.int/display/CKB/ERA5+family+post-processed+daily+statistics+documentation) # nolint: line_length_linter
#'

datacube_aggregation <- function(
  input_path,
  output_filename = "",
  fun = mean,
  cores = 1,
  mode = c("agg_fun", "value_at_hour")[1],
  value_hour = 0,
  date_shift_days = 0,
  drop_first_layer = FALSE,
  ...
) {
  mode <- match.arg(mode, c("agg_fun", "value_at_hour"))
  validate_function(fun, "fun")
  validate_scalar_logical(drop_first_layer, "drop_first_layer")
  if (
    !is.numeric(value_hour) ||
      length(value_hour) != 1 ||
      is.na(value_hour) ||
      !is.finite(value_hour) ||
      value_hour != as.integer(value_hour) ||
      value_hour < 0 ||
      value_hour > 23
  ) {
    stop("The argument 'value_hour' must be a whole number from 0 to 23.")
  }
  if (
    !is.numeric(date_shift_days) ||
      length(date_shift_days) != 1 ||
      is.na(date_shift_days) ||
      !is.finite(date_shift_days) ||
      date_shift_days != as.integer(date_shift_days)
  ) {
    stop("The argument 'date_shift_days' must be a whole number.")
  }
  value_hour <- as.integer(value_hour)
  date_shift_days <- as.integer(date_shift_days)

  cube_i <- input_raster(input_path)

  timestamp <- names_to_date(cube_i, ...)

  terra::time(cube_i, tstep = "") <- timestamp

  if (mode == "agg_fun") {
    agg_raster <- terra::tapp(
      x = cube_i,
      index = "days",
      fun = fun,
      cores = cores,
      filename = output_filename,
      overwrite = TRUE
    )
  } else if (mode == "value_at_hour") {
    selected_layers <- which(as.POSIXlt(timestamp)$hour == value_hour)

    if (drop_first_layer) {
      selected_layers <- selected_layers[-1]
    }

    if (length(selected_layers) == 0) {
      stop("No raster layers were found at value_hour = ", value_hour, ".")
    }

    agg_raster <- cube_i[[selected_layers]]
    output_time <- timestamp[selected_layers] +
      as.difftime(date_shift_days, units = "days")

    terra::time(agg_raster, tstep = "") <- output_time
    names(agg_raster) <- paste0("d_", format(as.Date(output_time), "%Y.%m.%d"))

    if (output_filename != "") {
      agg_raster <- terra::writeRaster(
        agg_raster,
        filename = output_filename,
        overwrite = TRUE
      )
    }
  }

  if (output_filename != "") {
    agg_raster
  }
}
