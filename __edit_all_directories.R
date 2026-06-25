# First run it with: 
# dry_run <- TRUE
# Then, after checking the preview, change to: 
# dry_run <- FALSE



# Rename Smaers Table S1 part names in:
#   1) file names, recursively
#   2) contents of .R and .md files, recursively

root <- path.expand(
  "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"
)

replacements <- c(
  "Smaers_etal_2017_TableS1part1"       = "Smaers_etal_2017_TableS1part1",
  "Smaers_etal_2017_TableS1part2s" = "Smaers_etal_2017_TableS1part2"
)

# Set to FALSE after checking the printed preview
dry_run <- TRUE

replace_all <- function(x) {
  for (old in names(replacements)) {
    x <- gsub(
      pattern = old,
      replacement = replacements[[old]],
      x = x,
      fixed = TRUE,
      useBytes = TRUE
    )
  }
  x
}

# ------------------------------------------------------------
# 1) Replace text inside .R and .md files
# ------------------------------------------------------------

all_paths <- list.files(
  root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)

files <- all_paths[!file.info(all_paths)$isdir]

text_files <- files[
  tolower(tools::file_ext(files)) %in% c("r", "md")
]

changed_text_files <- character()

for (f in text_files) {
  size <- file.info(f)$size
  
  if (is.na(size) || size == 0) next
  
  txt <- readChar(f, nchars = size, useBytes = TRUE)
  new_txt <- replace_all(txt)
  
  if (!identical(txt, new_txt)) {
    changed_text_files <- c(changed_text_files, f)
    
    if (!dry_run) {
      con <- file(f, open = "wb")
      writeChar(new_txt, con, eos = NULL, useBytes = TRUE)
      close(con)
    }
  }
}

# ------------------------------------------------------------
# 2) Rename files whose names contain the old strings
# ------------------------------------------------------------

new_basenames <- replace_all(basename(files))
rename_from <- files[new_basenames != basename(files)]
rename_to <- file.path(dirname(rename_from), new_basenames[new_basenames != basename(files)])

# Check for duplicate target names
if (anyDuplicated(rename_to)) {
  stop(
    "Renaming would create duplicate file names:\n",
    paste(unique(rename_to[duplicated(rename_to)]), collapse = "\n")
  )
}

# Check for existing files that would be overwritten
already_exists <- file.exists(rename_to) & normalizePath(rename_from, mustWork = FALSE) != normalizePath(rename_to, mustWork = FALSE)

if (any(already_exists)) {
  stop(
    "Renaming would overwrite existing files:\n",
    paste(rename_to[already_exists], collapse = "\n")
  )
}

# Print preview
cat("\nFiles whose contents would be changed:\n")
cat(if (length(changed_text_files)) paste(changed_text_files, collapse = "\n") else "None")
cat("\n\nFiles that would be renamed:\n")

if (length(rename_from)) {
  cat(
    paste0(rename_from, "\n  -> ", rename_to, collapse = "\n\n")
  )
} else {
  cat("None")
}

cat("\n")

# Apply file renames
if (!dry_run && length(rename_from)) {
  ok <- file.rename(rename_from, rename_to)
  
  if (!all(ok)) {
    warning(
      "Some files could not be renamed:\n",
      paste(rename_from[!ok], collapse = "\n")
    )
  }
}

if (dry_run) {
  message("\nDry run only. Set dry_run <- FALSE to apply changes.")
} else {
  message("\nDone.")
}