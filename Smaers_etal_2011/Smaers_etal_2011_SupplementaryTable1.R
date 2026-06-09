## Smaers JB, Steele J, Case CR, Cowper A, Amunts K, Zilles K (2011), Brain Behav Evol 77:67-78
## "Primate prefrontal cortex evolution: human brains are the extreme of a lateralized ape trend."
## Supplementary Table 1 = RAW per-individual frontal white/grey (L/R) + total brain volume (cm3).
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Smaers_etal_2011")
options(scipen = 999)
raw <- read.csv("Smaers_etal_2011_SupplementaryTable1_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
sp  <- sub("^([A-Z][a-z]+ [a-z]+).*$", "\\1", raw$Individual)          # genus + epithet
cat <- trimws(sub("^[A-Z][a-z]+ [a-z]+", "", raw$Individual))           # catalogue / collection no.
clean <- data.frame(
  species = sp, catalogue_number = cat,
  frontal_white_left_cm3  = raw[["Frontal left white"]],  frontal_grey_left_cm3  = raw[["Frontal left grey"]],
  frontal_white_right_cm3 = raw[["Frontal right white"]], frontal_grey_right_cm3 = raw[["Frontal right grey"]],
  frontal_white_total_cm3 = raw[["Frontal left white"]] + raw[["Frontal right white"]],
  frontal_grey_total_cm3  = raw[["Frontal left grey"]]  + raw[["Frontal right grey"]],
  total_brain_volume_cm3  = raw[["Total brain size"]], source = "Smaers_etal_2011", stringsAsFactors = FALSE)
write.csv(clean, "Smaers_etal_2011_SupplementaryTable1.csv", row.names = FALSE)
