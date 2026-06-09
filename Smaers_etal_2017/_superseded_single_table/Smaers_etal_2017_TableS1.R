## Smaers JB, Gomez-Robles A, Parks AN, Sherwood CC (2017), Current Biology 27:714-720
## "Exceptional Evolutionary Expansion of Prefrontal Cortex in Great Apes and Humans."
## Table S1 ("Smaers data") = species-level gray & white volumes for primary-visual / prefrontal /
## other-association / frontal-motor.  NB: COMPILED from Smaers 2010 [S1] + 2011 [S2] (+ Brodmann [S3]);
## not newly collected. Units stated mm3 in source but values scale as cm3 (match 2011) -- FLAG.
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Smaers_etal_2017")
options(scipen = 999)
clean <- read.csv("Smaers_etal_2017_TableS1_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
names(clean) <- c("species","primary_visual_gray","prefrontal_gray","other_association_gray","frontal_motor_gray",
                  "primary_visual_white","prefrontal_white","other_association_white","frontal_motor_white")
clean$species <- gsub(" ", "_", trimws(clean$species))
clean$source  <- "Smaers_etal_2017"
write.csv(clean, "Smaers_etal_2017_TableS1.csv", row.names = FALSE)
