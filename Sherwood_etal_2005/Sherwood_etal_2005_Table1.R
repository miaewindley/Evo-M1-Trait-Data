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
write_tsv(clean, file.path(folder, "Sherwood_etal_2005_Table1.tsv"))
# TSV for the merge (encoded name registered in __ReadMe.xlsx)
write_tsv(clean, file.path(base, "__Public/comparative-data/10.1016%2Fj.jhevol.2004.10.003_Table1.tsv"))

message("Sherwood 2005 Table 1: ", nrow(clean), " species written.")
