articles <- c(
  "era5-land-hourly-to-swat",
  "station-interpolation-workflow",
  "reproducing-the-case"
)

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg) == 0) {
  "vignettes/articles/precompile.R"
} else {
  sub("^--file=", "", script_arg[[1]])
}
article_dir <- dirname(normalizePath(script_path, mustWork = FALSE))

for (article in articles) {
  input <- file.path(article_dir, paste0(article, ".Rmd.orig"))
  output <- file.path(article_dir, paste0(article, ".Rmd"))

  if (!file.exists(input)) {
    stop("Missing article source: ", input)
  }

  knitr::knit(input = input, output = output, quiet = FALSE)
}
