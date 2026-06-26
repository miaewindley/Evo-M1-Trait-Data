# safely_guard_setwd_calls.R

root_dir <- getwd()

files <- list.files(
  root_dir,
  pattern = "\\.(R|Rmd|Qmd)$",
  recursive = TRUE,
  full.names = TRUE
)

# Do not edit runner scripts
files <- files[!grepl("run_all_scripts|safely_guard_setwd", basename(files))]

backup_dir <- file.path(root_dir, "_setwd_backup")
dir.create(backup_dir, showWarnings = FALSE)

target <- "setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data")"

replacement <- paste(
  'if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {',
  '  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data")',
  '}',
  sep = "\n"
)

changed <- character()

for (f in files) {
  txt <- readLines(f, warn = FALSE)
  
  if (!any(grepl(target, txt, fixed = TRUE))) {
    next
  }
  
  rel <- sub(paste0("^", normalizePath(root_dir), "/?"), "", normalizePath(f))
  backup_file <- file.path(backup_dir, rel)
  dir.create(dirname(backup_file), recursive = TRUE, showWarnings = FALSE)
  file.copy(f, backup_file, overwrite = TRUE)
  
  txt2 <- gsub(target, replacement, txt, fixed = TRUE)
  
  writeLines(txt2, f)
  changed <- c(changed, f)
  
  cat("Updated:", f, "\n")
}

cat("\nDone.\n")
cat("Files updated:", length(changed), "\n")
cat("Backups saved in:", backup_dir, "\n")
