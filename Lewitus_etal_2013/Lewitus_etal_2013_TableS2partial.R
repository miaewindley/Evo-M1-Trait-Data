# Lewitus et al. 2013 — Table 1 (a.k.a. Suppl. Table S2, partial) → CSV + TSV
# doi:10.3389/fnhum.2013.00424
# Composite table: brain weight + ventricle (Stephan 1981), neuron/astrocyte
# density (Lewitus 2012), GI (Lewitus 2013). Mostly secondary / re-used data.

library(readxl)
repo <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"
setwd(repo)
folder <- "Lewitus_etal_2013"; item_name <- "Lewitus_etal_2013_TableS2partial"

key <- read.csv("_keys/Stephan/species_key.csv", stringsAsFactors = FALSE)
ref <- read.csv("_keys/species_reference.csv",   stringsAsFactors = FALSE)$accepted_name
km  <- setNames(key$accepted_name, tolower(trimws(key$variant_name)))
clean_sp <- function(x) trimws(gsub("\\s+", " ", gsub("_", " ", gsub("\\*", "", x))))
resolve <- function(x) { c <- clean_sp(x)
  h <- match(tolower(c), tolower(ref)); if (!is.na(h)) return(ref[h])
  a <- km[tolower(c)]; if (!is.na(a)) return(unname(a)); c }

snap <- read_excel(file.path(folder, paste0(item_name, "_snapshot.xlsx")),
                   sheet = "TableS2partial_snapshot", skip = 1, .name_repair = "minimal")
snap <- as.data.frame(snap, check.names = FALSE)
snap <- snap[!is.na(snap$Species) & nzchar(trimws(snap$Species)), ]

ren <- c("Brain weight (g)"="Brain_weight_g",
         "Neuron density (per mm3)"="Neuron_density_per_mm3",
         "Astrocyte density (per mm.)"="Astrocyte_density_per_mm3",
         "Gray matter thickness (mm)"="Gray_matter_thickness_mm",
         "Ventricle (1 and 2) volume (mm3)"="Ventricle_1_2_volume_mm3",
         "GI"="GI")
nm <- names(snap); nm[nm %in% names(ren)] <- ren[nm[nm %in% names(ren)]]; names(snap) <- nm

df <- cbind(species_sci = vapply(snap$Species, resolve, character(1)),
            snap, stringsAsFactors = FALSE)

write.csv(df, file.path(folder, paste0(item_name, ".csv")),
          row.names = FALSE, fileEncoding = "UTF-8")
filecodes    <- read_excel("__ReadMe.xlsx", sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
if (is.na(item_encoded)) item_encoded <- "10.3389%2Ffnhum.2013.00424_TableS2partial"
tsv_dir <- "__Public/comparative-data/"
if (dir.exists(tsv_dir))
  write.table(df, paste0(tsv_dir, item_encoded, ".tsv"),
              sep = "\t", row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")
cat("Lewitus 2013 TableS2partial:", nrow(df), "species written\n")
