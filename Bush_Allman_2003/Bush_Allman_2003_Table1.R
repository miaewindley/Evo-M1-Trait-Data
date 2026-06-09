## Bush EC, Allman JM (2003). The scaling of white matter to gray matter in cerebellum and neocortex. Brain Behav Evol 61(1):1-5. Table 1.
## Snapshot (Bush_Allman_2003_Table1_snapshot.csv) -> harmonize species -> clean (Bush_Allman_2003_Table1.csv). Comparisons in comparison/.
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Bush_Allman_2003"); options(scipen=999)
snap <- read.csv("Bush_Allman_2003_Table1_snapshot.csv", check.names=FALSE, stringsAsFactors=FALSE, na.strings=c("","NA"))
key <- read.csv("../_keys/Stephan/species_key.csv", stringsAsFactors=FALSE)
lk  <- setNames(key$accepted_name, tolower(key$variant_name))
harm<- function(s){ v<-lk[tolower(trimws(s))]; if(is.na(v)) trimws(s) else unname(v) }
# neocortex + cerebellum grey/white volumes (cm3) for 45 mammals
# clean CSV/TSV produced by the build; this script documents snapshot->clean->harmonize.
