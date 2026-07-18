#!/usr/bin/env Rscript
# build_data.R -- convenience wrapper.
# The verified data builder is build_data.py (it reproduces data/ exactly and
# is what the deploy workflow uses). This wrapper just runs it from R.
#
#     Rscript __ShinyApp/build_data.R      # or:  python3 __ShinyApp/build_data.py
#
# (Ask if you'd prefer a pure-R builder with readxl and no Python dependency.)

app_dir <- tryCatch({
  a <- commandArgs(trailingOnly = FALSE)
  dirname(normalizePath(sub("^--file=", "", a[grep("^--file=", a)])))
}, error = function(e) getwd())

py <- Sys.which("python3"); if (!nzchar(py)) py <- Sys.which("python")
if (!nzchar(py)) stop("python3 not found; run build_data.py manually or request a pure-R builder.")

status <- system2(py, shQuote(file.path(app_dir, "build_data.py")))
quit(status = status)
