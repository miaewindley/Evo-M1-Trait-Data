# Lewitus et al. 2014 — Table S8 (neocortical neuron number, Fig 3d) → CSV + TSV
# Reformat: frozen snapshot -> full-precision, species-harmonised analysis output.
# NB: supplement download id .s020 is registered/cited as Table S8 but the sheet
# title reads "Table S9"; item name kept as TableS8 to match the registry.

library(readxl)
repo <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"
setwd(repo)
folder <- "Lewitus_etal_2014"; item_name <- "Lewitus_etal_2014_TableS8"

key <- read.csv("_keys/Stephan/species_key.csv", stringsAsFactors = FALSE)
ref <- read.csv("_keys/species_reference.csv",   stringsAsFactors = FALSE)$accepted_name
km  <- setNames(key$accepted_name, tolower(trimws(key$variant_name)))
clean_sp <- function(x) trimws(gsub("\\s+", " ", gsub("_", " ", gsub("\\*", "", x))))
resolve <- function(x) { c <- clean_sp(x)
  h <- match(tolower(c), tolower(ref)); if (!is.na(h)) return(ref[h])
  a <- km[tolower(c)]; if (!is.na(a)) return(unname(a)); c }

snap <- read_excel(file.path(folder, paste0(item_name, "_snapshot.xlsx")),
                   sheet = "TableS8_snapshot", skip = 1, .name_repair = "minimal")
snap <- as.data.frame(snap, check.names = FALSE)
snap <- snap[!is.na(snap$Species) & nzchar(trimws(snap$Species)), ]

df <- data.frame(
  species_sci     = vapply(snap$Species, resolve, character(1)),
  Species         = trimws(snap$Species),
  # full-precision integer (source stores it as an integer; the old public TSV
  # had rounded it to scientific notation)
  Neuronal_number = format(suppressWarnings(as.numeric(snap[["Neuronal number"]])),
                           scientific = FALSE, trim = TRUE),
  GI              = snap$GI,
  stringsAsFactors = FALSE, check.names = FALSE
)

write.csv(df, file.path(folder, paste0(item_name, ".csv")),
          row.names = FALSE, fileEncoding = "UTF-8")
filecodes    <- read_excel("__ReadMe.xlsx", sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
tsv_dir <- "__Public/comparative-data/"
if (!is.na(item_encoded) && dir.exists(tsv_dir))
  write.table(df, paste0(tsv_dir, item_encoded, ".tsv"),
              sep = "\t", row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")
cat("Lewitus TableS8:", nrow(df), "species written\n")
