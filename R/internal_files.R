#' Extract the file name
#'
#' This function extracts the file name without the extension from a file path.
#' It is an internal function used in the \code{unit_converter} function.
#'
#' @param path A character string with the file path.
#'
#' @return A character string with the file name without the extension.
#'
#' @keywords internal
#'
file_name <- function(path) {
  # Get basename first to handle different path separators
  base <- basename(path)
  # Remove extension
  name <- tools::file_path_sans_ext(base)
  name
}


#' Create a directory if it does not exist
#'
#' This function creates a directory if it does not exist.
#' It is an internal function used in the \code{unit_converter} function.
#'
#' @param folder_path A character string with the path of the directory to be
#' created.
#' @param return_path logical. If \code{TRUE}, the function returns the path
#'
#' @keywords internal
#'
#' @return NULL. Only for side effects.
#'
touch_dir <- function(folder_path, return_path = FALSE) {
  if (!dir.exists(folder_path)) {
    dir.create(folder_path, recursive = TRUE)
  }
  if (return_path) {
    folder_path
  }
}


#' Clean a directory if it exists
#' This function removes files and/or sub-directory within the
#' directory if exists.
#'
#' @param folder_path A character string with the path of the directory to be
#' cleaned.
#'
#' @keywords internal
#'
#' @return NULL. Only for side effects.
#'
clean_dir <- function(folder_path) {
  if (dir.exists(folder_path)) {
    unlink(folder_path, recursive = TRUE)
  }
}
