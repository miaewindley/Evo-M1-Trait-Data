## Semendeferi K, Armstrong E, Schleicher A, Zilles K, Van Hoesen GW (2001),
## Am J Phys Anthropol 114(3):224-241 — "Prefrontal Cortex in Humans and Apes: A Comparative Study of Area 10"
## Table 2: Volumes of the brain and area 10 in all hominoids (mm3). Snapshot -> clean.
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Semendeferi_etal_2001")
options(scipen = 999)
raw <- read.csv("Semendeferi_etal_2001_Table2_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
binom <- c(Human="Homo sapiens", Chimpanzee="Pan troglodytes", Bonobo="Pan paniscus",
           Gorilla="Gorilla gorilla", Orangutan="Pongo pygmaeus", Gibbon="Hylobates lar")
num <- function(x) as.numeric(gsub(",", "", x))
clean <- data.frame(species = unname(binom[raw$Species]),
                    brain_volume_mm3 = num(raw$Brain),
                    area10_volume_mm3 = num(raw[["Area 10"]]),
                    area10_hemisphere = "right", n = 1L, source = "Semendeferi_etal_2001",
                    note = ifelse(raw$Species == "Gorilla", "area 10 = frontal pole cortex", ""),
                    stringsAsFactors = FALSE)
# Footnotes: brain = total brain (mm3); area 10 = right hemisphere; one individual/species.
write.csv(clean, "Semendeferi_etal_2001_Table2.csv", row.names = FALSE)
