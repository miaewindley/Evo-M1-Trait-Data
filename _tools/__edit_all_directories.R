# First run it with: 
# dry_run <- TRUE
# Then, after checking the preview, change to: 
# dry_run <- FALSE



# Rename  in:
#   1) file names, recursively
#   2) contents of .R and .md files, recursively

## project root = nearest ancestor containing __ReadMe.xlsx (works from _tools/ or root,
## and on any clone, via Rscript / source() / RStudio)
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
root <- local({
  d <- if (file.exists(.script_path)) dirname(.script_path) else normalizePath(getwd())
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d
  else if (file.exists(.script_path)) dirname(.script_path) else normalizePath(getwd())
})

# Fill these in before running (old = new). Left empty, R's parser rejects `'' = ''`
# as a zero-length variable name -- that was the crash under the automated batch runner.
# character(0) is the correct "nothing to replace yet" placeholder: replace_all() below
# just loops over names(replacements), so an empty vector makes it a safe no-op.
replacements <- character(0)

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