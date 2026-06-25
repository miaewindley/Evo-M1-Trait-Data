## MacLeod et al. 2003, J Hum Evol 44:401-429 — Table 1 (Yerkes sample)
## Snapshot -> clean. Per-specimen volumes (cm3): whole brain, cerebellum, vermis, hemispheres.
## Golden rule: the snapshot is frozen/faithful; ALL cleaning happens here.

options(scipen = 999)
script_path <- normalizePath(rstudioapi::getActiveDocumentContext()$path)
folder <- dirname(script_path)
base   <- dirname(folder)
setwd(folder)

## --- locate paths (portable: Rscript or RStudio) ---
.this <- tryCatch({
  a <- commandArgs(FALSE); f <- sub("^--file=", "", a[grepl("^--file=", a)])
  if (length(f) && nzchar(f[1])) normalizePath(f[1])
  else if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
    normalizePath(rstudioapi::getActiveDocumentContext()$path)
  else NA_character_
}, error = function(e) NA_character_)
paper_dir      <- if (!is.na(.this)) dirname(.this) else getwd()
dataset_root   <- dirname(paper_dir)
public_tsv_dir <- file.path(dataset_root, "__Public", "comparative-data")
setwd(paper_dir)

raw <- read.csv("MacLeod_etal_2003_Table1_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
spec <- raw$Specimen

# Footnote markers carried in the Specimen cell (Table 2 legend applies to both tables):
#   †  from the Stephan Collection   ‡  brain weight not known
#   *  horizontal sections           §  sagittal sections   (default: coronal)
has_star <- grepl("*", spec, fixed = TRUE)
has_sec  <- grepl("§", spec, fixed = TRUE)
clean_species <- function(s) {
  s  <- gsub("[*†‡§]", "", s); s <- trimws(sub("\\(.*$", "", s)); tk <- strsplit(s, "\\s+")[[1]]
  out <- trimws(paste(tk[1], if (length(tk) >= 2) tk[2] else ""))
  if (length(tk) >= 3 && grepl("^[a-z]+$", tk[3])) out <- paste(out, tk[3]); out
}
as_num <- function(x) suppressWarnings(as.numeric(x))

clean <- data.frame(
  species               = vapply(spec, clean_species, character(1), USE.NAMES = FALSE),
  specimen              = trimws(gsub("\\s*[*†‡§]+", "", spec)),
  sex                   = raw$Sex,
  sample                = "Yerkes",
  brain_volume_cm3      = as_num(raw[["Brain volume cm3"]]),
  cerebellum_volume_cm3 = as_num(raw[["Cerebellum volume cm3"]]),
  vermis_volume_cm3     = as_num(raw[["Vermis volume cm3"]]),
  hemisphere_volume_cm3 = as_num(raw[["Hemisphere volume cm3"]]),
  stephan_collection    = grepl("†", spec, fixed = TRUE),
  section_plane         = ifelse(has_star & has_sec, "mixed", ifelse(has_star, "horizontal", ifelse(has_sec, "sagittal", "coronal"))),
  brainweight_known     = !grepl("‡", spec, fixed = TRUE),
  source                = "MacLeod_etal_2003",
  stringsAsFactors = FALSE
)
## ---- local CSV: use this R script's filename ----
script_path <- rstudioapi::getActiveDocumentContext()$path
if (!nzchar(script_path)) {
  stop("Save the R script before running it.")
}
script_path <- normalizePath(script_path)
folder    <- dirname(script_path)
base      <- dirname(folder)
item_name <- tools::file_path_sans_ext(basename(script_path))
csv_file <- file.path(folder, paste0(item_name, ".csv"))
write.csv(clean, csv_file, row.names = FALSE)
message(item_name, ": ", nrow(clean), " rows written to ", basename(csv_file))

## ---- public TSV: look up the DOI/PMID code from __ReadMe.xlsx ----
tsv_dir <- file.path(base, "__Public", "comparative-data")
filecodes <- readxl::read_excel(
  file.path(base, "__ReadMe.xlsx"),
  sheet = "Sheet1"
)
item_encoded <- filecodes$`Item encoded`[
  match(item_name, filecodes$`Item name`)
]

if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  tsv_file <- file.path(path.expand(tsv_dir), paste0(item_encoded, ".tsv"))
  write.table(
    clean,
    tsv_file,
    sep = "\t",
    row.names = FALSE
  )
  message("Wrote ", tsv_file)
}