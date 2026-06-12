## Semendeferi K, Armstrong E, Schleicher A, Zilles K, Van Hoesen GW (2001),
## Am J Phys Anthropol 114(3):224-241 — "Prefrontal Cortex in Humans and Apes: A Comparative Study of Area 10"
## Table 2: Volumes of the brain and area 10 in all hominoids (mm3). Snapshot -> clean.
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Semendeferi_etal_2001")
script_path   <- rstudioapi::getActiveDocumentContext()$path
paper_dir     <- dirname(script_path)
dataset_root  <- dirname(paper_dir)
table_name    <- tools::file_path_sans_ext(basename(script_path))

# outputs
snapshot_xlsx  <- file.path(paper_dir, paste0(table_name, "_snapshot.xlsx"))
final_csv     <- file.path(paper_dir, paste0(table_name, ".csv"))
readme_xlsx   <- file.path(dataset_root, "__ReadMe.xlsx")
public_tsv_dir<- file.path(dataset_root, "__Public", "comparative-data")

options(scipen = 999)
raw <- read.csv("Semendeferi_etal_2001_TABLE2_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
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
write.csv(clean, "Semendeferi_etal_2001_TABLE2.csv", row.names = FALSE)

# ------------------------------------------------------------
# 8) Save (LOCAL CSV + PUBLIC TSV)
# ------------------------------------------------------------

final.dataframe <- clean

# Item encoded lookup uses table_name (script filename)
filecodes <- read_excel(file.path(dataset_root, "__ReadMe.xlsx"), sheet = "Sheet1")
item_encoded <- filecodes$`Item encoded`[match(table_name, filecodes$`Item name`)]

# Local output next to the paper
write.csv(final.dataframe, final_csv, row.names = FALSE)

# Public TSV output
dir.create(public_tsv_dir, recursive = TRUE, showWarnings = FALSE)
write.table(final.dataframe,
            file = file.path(public_tsv_dir, paste0(item_encoded, ".tsv")),
            sep = "\t", row.names = FALSE)


