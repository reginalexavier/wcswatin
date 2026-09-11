## Test environments

* local Omarchy 4.0.2 (Arch Linux), R 4.6.1, checked 2026-09-11
* GitHub Actions macOS latest, R release
* GitHub Actions Windows latest, R release
* GitHub Actions Ubuntu latest, R devel
* GitHub Actions Ubuntu latest, R release
* GitHub Actions Ubuntu latest, R oldrel-1

## R CMD check results

0 errors | 0 warnings | 0 notes

## Submission notes

This is a resubmission of version 0.2.0 following CRAN feedback.

* Replaced the invalid relative file URI in the package vignette with a button
  that opens the embedded workflow image without referencing a local file.
* Removed the superseded 'raster' package dependency and standardized spatial
  raster workflows on 'terra' and `SpatRaster`.
* Updated `ts_to_area()` to return a multi-layer `SpatRaster` and preserve input
  file stems as layer names.
* Removed support for legacy `RasterLayer`, `RasterStack`, and `RasterBrick`
  objects in `input_raster()`.

## Downstream dependencies

There are no downstream dependencies.
