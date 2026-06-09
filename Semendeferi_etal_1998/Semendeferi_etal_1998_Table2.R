## Semendeferi K, Armstrong E, Schleicher A, Zilles K, Van Hoesen GW (1998),
## Am J Phys Anthropol 106(2):129-155 — "Limbic Frontal Cortex in Hominoids: A Comparative Study of Area 13"
## Table 2: Volumes of the brain and area 13 (mm3). Snapshot -> clean.
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Semendeferi_etal_1998")
options(scipen = 999)
raw <- read.csv("Semendeferi_etal_1998_Table2_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
binom <- c(Human="Homo sapiens", Chimpanzee="Pan troglodytes", Bonobo="Pan paniscus",
           Gorilla="Gorilla gorilla", Orangutan="Pongo pygmaeus", Gibbon="Hylobates lar")
num <- function(x) as.numeric(gsub(",", "", x))
clean <- data.frame(species = unname(binom[raw$Species]),
                    brain_volume_mm3 = num(raw$Brain),
                    area13_volume_mm3 = num(raw[["Area 13"]]),
                    area13_hemisphere = "right", n = 1L, source = "Semendeferi_etal_1998",
                    stringsAsFactors = FALSE)
# Footnotes: brain = total brain structure (mm3); area 13 = right hemisphere; one individual/species.
write.csv(clean, "Semendeferi_etal_1998_Table2.csv", row.names = FALSE)
