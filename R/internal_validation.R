#' Validate a scalar character argument
#'
#' @param value Argument value.
#' @param arg Argument name.
#'
#' @noRd
#'
validate_scalar_character <- function(value, arg) {
  if (!is.character(value) || length(value) != 1 || is.na(value)) {
    stop("The argument '", arg, "' must be a single character value.")
  }
}


#' Validate a scalar logical argument
#'
#' @param value Argument value.
#' @param arg Argument name.
#'
#' @noRd
#'
validate_scalar_logical <- function(value, arg) {
  if (!is.logical(value) || length(value) != 1 || is.na(value)) {
    stop("The argument '", arg, "' must be TRUE or FALSE.")
  }
}


#' Validate an input directory argument
#'
#' @param path Directory path.
#' @param arg Argument name.
#'
#' @noRd
#'
validate_input_dir <- function(path, arg) {
  validate_scalar_character(path, arg)
  if (!dir.exists(path)) {
    stop("The directory provided in '", arg, "' does not exist: ", path)
  }
}


#' Validate a positive whole-number argument
#'
#' @param value Argument value.
#' @param arg Argument name.
#'
#' @noRd
#'
validate_positive_whole_number <- function(value, arg) {
  if (
    !is.numeric(value) ||
      length(value) != 1 ||
      is.na(value) ||
      value < 1 ||
      value != as.integer(value)
  ) {
    stop("The argument '", arg, "' must be a positive whole number.")
  }
}


#' Validate that an argument is a function
#'
#' @param value Argument value.
#' @param arg Argument name.
#'
#' @noRd
#'
validate_function <- function(value, arg) {
  if (!is.function(value)) {
    stop("The argument '", arg, "' must be a function.")
  }
}


#' Validate that files were found
#'
#' @param files Character vector of files.
#' @param folder Directory searched.
#' @param pattern File pattern used.
#' @param label Human-readable file description.
#'
#' @noRd
#'
validate_files_found <- function(files, folder, pattern, label = "files") {
  if (length(files) == 0) {
    stop(
      "No ", label, " found in '", folder, "' matching pattern '", pattern, "'."
    )
  }
}
