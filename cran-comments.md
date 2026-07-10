## Test environments

* local Ubuntu 24.04.4 LTS, R 4.6.1 (2026-07-10)
* GitHub Actions macOS latest, R release
* GitHub Actions Windows latest, R release
* GitHub Actions Ubuntu latest, R devel
* GitHub Actions Ubuntu latest, R release
* GitHub Actions Ubuntu latest, R oldrel-1

## R CMD check results

0 errors | 0 warnings | 0 notes

## Submission notes

This is a resubmission of version 0.1.1 following CRAN feedback.

* Rewrote the title and description to quote and explain 'SWAT', and added the
  canonical 'SWAT' reference with its DOI.
* Added explicit return-value documentation for `save_daily_tbl()` and
  `table_to_files()`.
* Replaced commented pseudo-examples and `\dontrun{}` with short executable
  examples that use temporary files and clean them up.
* Regenerated the Rd files from the updated roxygen source.

## Downstream dependencies

There are no downstream dependencies.
