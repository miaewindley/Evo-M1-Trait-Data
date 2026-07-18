## Finlay, Cheung & Darlington 2006 — "Developmental constraints on or developmental structure in
## brain evolution", in: Munakata & Johnson (eds) Attention & Performance XXI (OUP). Table 6.1.
## doi:10.1093/oso/9780198568742.003.0006
## Per-species: body/brain weight, visual/somatomotor/total cortical areas, total cortical area.
## This script: type the numbers, keep the printed name, and resolve a canonical binomial `Species`
## (fixing sp.-level labels + typos) via the reviewable common_name_to_species.csv.
## Golden rule: the snapshot is frozen; all cleaning happens here.

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

## ---- read frozen snapshot (Common Name, Species Name = printed binomial, then the numbers) ----
library(readxl)
raw <- read_excel("Finlay_etal_2006_Table6.1_snapshot.xlsx",
                  col_types = c("text","text","numeric","numeric","numeric","numeric","numeric","numeric"))

common_name          <- trimws(raw[["Common Name"]])
species_as_published <- trimws(raw[["Species Name"]])    # journal's printed name, kept verbatim (invariant)

## ---- resolve canonical binomial from the reviewable mapping (no inline hardcoding) ----
map     <- read.csv(file.path(folder, "common_name_to_species.csv"), stringsAsFactors = FALSE)
Species <- map$Species[match(species_as_published, map$species_as_published)]
if (any(is.na(Species)))
  warning("No binomial for: ", paste(species_as_published[is.na(Species)], collapse = ", "),
          " — add a row to common_name_to_species.csv")

clean <- data.frame(
  Species              = Species,                        # canonical binomial (join key)
  common_name          = common_name,                    # printed common name (archival)
  species_as_published = species_as_published,           # journal's printed name (verbatim)
  bodyweight_g         = raw[["Bodyweight(g)"]],
  brainweight_g        = raw[["Brainweight(g)"]],
  visual_areas         = raw[["Visual Areas"]],
  somatomotor_areas    = raw[["Somatomotor Areas"]],
  total_areas          = raw[["Total Areas"]],
  cortical_area_mm2    = raw[["Cortical Area (mm2)"]],
  source               = item_name,
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
