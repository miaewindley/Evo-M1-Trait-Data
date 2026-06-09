## Smaers JB et al. (2011) Brain Behav Evol 77:67-78 — Supplementary Table 2
## Cumulative white/grey volume (cm3) up to the 5th section of the anterior frontal (Figs 2,4,5).
## Source: 000323671_sm_suppltables.pdf (p.2). Snapshot -> clean.
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Smaers_etal_2011")
options(scipen = 999)
raw <- read.csv("Smaers_etal_2011_SupplementaryTable2_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
sp  <- sub("^([A-Z][a-z]+ [a-z]+).*$", "\\1", raw$Individual)
cat <- trimws(sub("^[A-Z][a-z]+ [a-z]+", "", raw$Individual))
g <- function(col) raw[[col]]
clean <- data.frame(species=sp, catalogue_number=cat,
  sec5_white_left_cm3=g("Section interval 5 left white"), sec5_grey_left_cm3=g("Section interval 5 left grey"),
  sec5_white_right_cm3=g("Section interval 5 right white"), sec5_grey_right_cm3=g("Section interval 5 right grey"),
  sec5_white_total_cm3=g("Section interval 5 left white")+g("Section interval 5 right white"),
  sec5_grey_total_cm3 =g("Section interval 5 left grey") +g("Section interval 5 right grey"),
  source="Smaers_etal_2011", stringsAsFactors=FALSE)
write.csv(clean, "Smaers_etal_2011_SupplementaryTable2.csv", row.names = FALSE)
