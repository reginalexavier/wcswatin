## Test environments

* local Omarchy 4.0.2 (Arch Linux), R 4.6.1, checked 2026-09-09
* GitHub Actions macOS latest, R release
* GitHub Actions Windows latest, R release
* GitHub Actions Ubuntu latest, R devel
* GitHub Actions Ubuntu latest, R release
* GitHub Actions Ubuntu latest, R oldrel-1

## R CMD check results

0 errors | 0 warnings | 0 notes

## Submission notes

This is an update to version 0.2.0.

* Removed the superseded 'raster' package dependency and standardized spatial
  raster workflows on 'terra' and `SpatRaster`.
* Updated `ts_to_area()` to return a multi-layer `SpatRaster` and preserve input
  file stems as layer names.
* Removed support for legacy `RasterLayer`, `RasterStack`, and `RasterBrick`
  objects in `input_raster()`.

## Downstream dependencies

There are no downstream dependencies.
