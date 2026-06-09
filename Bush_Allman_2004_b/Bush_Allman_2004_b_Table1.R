## Bush EC, Allman JM (2004). Three-dimensional structure and evolution of primate primary visual cortex. Anat Rec A 281(1):1088-1094. Table 1.
## Snapshot (Bush_Allman_2004__b_Table1_snapshot.csv) -> harmonize species -> clean (Bush_Allman_2004_b_Table1.csv). Comparisons in comparison/.
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Bush_Allman_2004_b"); options(scipen=999)
snap <- read.csv("Bush_Allman_2004_b_Table1_snapshot.csv", check.names=FALSE, stringsAsFactors=FALSE, na.strings=c("","NA"))
key <- read.csv("../_keys/Stephan/species_key.csv", stringsAsFactors=FALSE)
lk  <- setNames(key$accepted_name, tolower(key$variant_name))
harm<- function(s){ v<-lk[tolower(trimws(s))]; if(is.na(v)) trimws(s) else unname(v) }
# V1 grey, LGN, V1 surface, horizontal meridian, whole brain, neocortex W/G (cm3) per primate
# clean CSV/TSV produced by the build; this script documents snapshot->clean->harmonize.
