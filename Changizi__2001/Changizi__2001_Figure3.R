## Changizi 2001, Biol Cybern 82:207-215 — Figure 3 (log #cortical areas vs log neocortical grey-matter volume)
## Data are only given in the Fig. 3 caption (not a printed table), so a snapshot table was made by hand:
##   Changizi__2001_Figure3_snapshot.csv  (Species = COMMON NAME, log brain volume, log # areas)
## This script: unlog the two axes, and ADD a binomial `Species` column (common names -> binomials via
## the reviewable common_name_to_species.csv). Golden rule: the snapshot is frozen; all cleaning is here.

options(scipen = 999)
## ---- paths: self-contained (Rscript or RStudio; full repo or lone folder) ----
.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)             # Rscript file.R
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getSourceEditorContext()$path                    # RStudio: Source
    if (!nzchar(p)) p <- rstudioapi::getActiveDocumentContext()$path  # RStudio: Run
    if (nzchar(p)) return(normalizePath(p))
  }
  stop("Run with Rscript file.R, or open in RStudio and click Source (save first).", call. = FALSE)
})
folder    <- dirname(.sp)                                # this paper's folder
item_name <- tools::file_path_sans_ext(basename(.sp))    # = file name, matches __ReadMe.xlsx
base      <- local({                                     # repo root; NA if run as a lone folder
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)

## ---- read frozen snapshot (Species column holds COMMON names) ----
raw <- read.csv("Changizi__2001_Figure3_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
common_name <- trimws(raw[[1]])                          # first column = common name

## ---- unlog the two log10 axes (as in the caption); truncate to integers (log-derived, not significant) ----
log_brain <- as.numeric(raw[[2]])                       # col 2 = log10 brain volume
log_areas <- as.numeric(raw[[3]])                       # col 3 = log10 # areas
brain_volume_mm3 <- trunc(10^log_brain)
n_areas          <- trunc(10^log_areas)

## ---- add binomial Species from the reviewable mapping (no inline hardcoding) ----
map <- read.csv(file.path(folder, "common_name_to_species.csv"), stringsAsFactors = FALSE)
Species <- map$Species[match(tolower(common_name), tolower(map$common_name))]
if (any(is.na(Species)))
  warning("No binomial for: ", paste(common_name[is.na(Species)], collapse = ", "),
          " — add a row to common_name_to_species.csv")

clean <- data.frame(
  Species          = Species,                            # canonical binomial (join key)
  common_name      = common_name,                        # printed common name (archival)
  log_brain_volume = log_brain,                          # log10 neocortical grey-matter volume (mm3), as printed
  log_n_areas      = log_areas,                          # log10 number of cortical areas, as printed
  brain_volume_mm3 = brain_volume_mm3,                   # unlogged neocortical grey-matter volume (mm3)
  n_areas          = n_areas,                            # unlogged number of cortical areas
  source           = item_name,
  stringsAsFactors = FALSE
)

## ---- local CSV ----
csv_file <- file.path(folder, paste0(item_name, ".csv"))
write.csv(clean, csv_file, row.names = FALSE)
message(item_name, ": ", nrow(clean), " rows written to ", basename(csv_file))

## ---- public TSV: look up the DOI code from __ReadMe.xlsx ----
tsv_dir <- file.path(base, "__Public", "comparative-data")
item_encoded <- if (!is.na(base) && file.exists(file.path(base, "__ReadMe.xlsx"))) {
  filecodes <- readxl::read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
  filecodes$`Item encoded`[match(item_name, filecodes$`Item name`)]
} else NA_character_

if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  tsv_file <- file.path(path.expand(tsv_dir), paste0(item_encoded, ".tsv"))
  write.table(clean, tsv_file, sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_file)
}
