# Sherwood et al. 2005 - Table 1 reformat
# Sherwood CC, Holloway RL, Erwin JM, Schleicher A, Zilles K, Hof PR (2005).
# "Cortical orofacial motor representation in Old World monkeys, great apes,
#  and humans..." (Brain Behav Evol) -- Table 1: medulla + orofacial motor
# nuclei volumes (left side only) (mm3).
#
# Reads the frozen faithful snapshot and writes the clean analysis CSV plus a
# DOI/stem-coded TSV for the volume merge. Medulla = whole structure; Vmo, VII,
# XII = LEFT side only (paper: "Only one side was analyzed because ... cranial
# nerve motor nuclei do not exhibit morphometric asymmetries").

library(tidyverse)
base <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"
folder <- file.path(base, "Sherwood_etal_2005")

snap <- read.csv(file.path(folder, "Sherwood_etal_2005_Table1_snapshot.csv"),
                 stringsAsFactors = FALSE, check.names = FALSE)
numv <- function(x) suppressWarnings(as.numeric(gsub(",", "", trimws(as.character(x)))))

clean <- tibble(
  species               = trimws(snap$species),
  N                     = numv(snap$N),
  medulla_oblongata_mm3 = numv(snap$Medulla_volume_Mean),
  medulla_oblongata_SD  = numv(snap$Medulla_volume_SD),
  trigeminal_motor_Vmo_mm3 = numv(snap$Vmo_volume_Mean),   # left side only
  trigeminal_motor_Vmo_SD  = numv(snap$Vmo_volume_SD),
  facial_VII_mm3        = numv(snap$VII_volume_Mean),       # left side only
  facial_VII_SD         = numv(snap$VII_volume_SD),
  hypoglossal_XII_mm3   = numv(snap$XII_volume_Mean),       # left side only
  hypoglossal_XII_SD    = numv(snap$XII_volume_SD),
  source                = "Sherwood_2005"
)

write_csv(clean, file.path(folder, "Sherwood_etal_2005_Table1.csv"))
message("Sherwood 2005 Table 1: ", nrow(clean), " species written.")

## ---- TSV for the merge: look up the DOI/PMID code from __ReadMe.xlsx (don't hardcode) ----
item_name    <- "Sherwood_etal_2005_Table1"
tsv_dir      <- file.path(base, "__Public/comparative-data/")
filecodes    <- readxl::read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' (DOI) for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  write_tsv(clean, file.path(tsv_dir, paste0(item_encoded, ".tsv")))
  message("Wrote ", tsv_dir, item_encoded, ".tsv")
}
