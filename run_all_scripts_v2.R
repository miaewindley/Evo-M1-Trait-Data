## project root = nearest ancestor containing __ReadMe.xlsx (clone-safe; Rscript/source/RStudio)
.script_path <- local({
  argv <- commandArgs(FALSE)
  f <- sub("^--file=", "", argv[grep("^--file=", argv)])
  if (length(f) == 1L && nzchar(f)) return(normalizePath(f))
  sf <- tryCatch(normalizePath(sys.frames()[[1]]$ofile), error = function(e) NULL)
  if (!is.null(sf) && nzchar(sf)) return(sf)
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getActiveDocumentContext()$path
    if (nzchar(p)) return(normalizePath(p))
  }
  normalizePath(getwd())
})
root_dir <- local({
  d <- if (file.exists(.script_path)) dirname(.script_path) else normalizePath(getwd())
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d
  else if (file.exists(.script_path)) dirname(.script_path) else normalizePath(getwd())
})
checks_dir <- file.path(root_dir, "_checks")
dir.create(checks_dir, showWarnings = FALSE, recursive = TRUE)

r_scripts <- list.files(
  root_dir,
  pattern = "\\.R$",
  recursive = TRUE,
  full.names = TRUE
)

r_scripts <- r_scripts[!grepl("run_all_scripts|safely_guard_setwd", basename(r_scripts))]

log_file <- file.path(checks_dir, "script_execution_log.csv")

run_log <- data.frame(
  script = r_scripts,
  status = rep(NA_character_, length(r_scripts)),
  error = rep(NA_character_, length(r_scripts)),
  start_time = rep(NA_character_, length(r_scripts)),
  end_time = rep(NA_character_, length(r_scripts)),
  elapsed_seconds = rep(NA_real_, length(r_scripts)),
  stringsAsFactors = FALSE
)

write.csv(run_log, log_file, row.names = FALSE)

for (i in seq_along(r_scripts)) {
  script <- r_scripts[i]
  
  cat(sprintf("\n[%d/%d] Running: %s\n", i, length(r_scripts), script))
  
  start <- Sys.time()
  run_log$start_time[i] <- as.character(start)
  run_log$status[i] <- "RUNNING"
  write.csv(run_log, log_file, row.names = FALSE)
  
  result <- system2(
    command = file.path(R.home("bin"), "Rscript"),
    args = shQuote(script),
    stdout = TRUE,
    stderr = TRUE,
    timeout = 300
  )
  
  exit_status <- attr(result, "status")
  if (is.null(exit_status)) exit_status <- 0
  
  end <- Sys.time()
  
  run_log$end_time[i] <- as.character(end)
  run_log$elapsed_seconds[i] <- as.numeric(difftime(end, start, units = "secs"))
  
  if (exit_status == 0) {
    run_log$status[i] <- "SUCCESS"
    run_log$error[i] <- ""
  } else {
    run_log$status[i] <- "FAILED"
    run_log$error[i] <- paste(result, collapse = "\n")
  }
  
  write.csv(run_log, log_file, row.names = FALSE)
}

cat("\nFinished. Log saved to:\n", log_file, "\n")

## ---- Summarise results ----

if (file.exists(log_file)) {
  
  log <- read.csv(log_file, stringsAsFactors = FALSE)
  
  failed <- subset(log, status == "FAILED")
  successful <- subset(log, status == "SUCCESS")
  
  write.csv(
    failed,
    file.path(checks_dir, "script_failures_only.csv"),
    row.names = FALSE
  )
  
  cat("\n=====================================\n")
  cat("Finished!\n")
  cat("=====================================\n")
  cat("Total scripts: ", nrow(log), "\n", sep = "")
  cat("Successful:    ", nrow(successful), "\n", sep = "")
  cat("Failed:        ", nrow(failed), "\n", sep = "")
  cat("\nFailure log written to:\n")
  cat(file.path(checks_dir, "script_failures_only.csv"), "\n")
  
  if (nrow(failed) > 0) {
    cat("\nFailed scripts:\n\n")
    print(failed[, c("script", "error")], row.names = FALSE)
  } else {
    cat("\nAll scripts completed successfully.\n")
  }
  
}

cat("\nFull execution log:\n")
cat(log_file, "\n")