# Lewitus et al. 2014 — Table S1 → analysis CSV + public TSV
# Reformat: frozen snapshot (journal spelling, incl. typos) -> corrected,
# species-harmonised analysis output. doi:10.1371/journal.pbio.1002000

library(readxl)

repo <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"
setwd(repo)
folder    <- "Lewitus_etal_2014"
item_name <- "Lewitus_etal_2014_TableS1"

# ---- species resolver (single source of truth = _keys) ----------------------
key <- read.csv("_keys/Stephan/species_key.csv", stringsAsFactors = FALSE)
ref <- read.csv("_keys/species_reference.csv",   stringsAsFactors = FALSE)$accepted_name
km  <- setNames(key$accepted_name, tolower(trimws(key$variant_name)))
clean_sp <- function(x) trimws(gsub("\\s+", " ", gsub("_", " ", gsub("\\*", "", x))))
resolve <- function(x) { c <- clean_sp(x)
  h <- match(tolower(c), tolower(ref)); if (!is.na(h)) return(ref[h])
  a <- km[tolower(c)]; if (!is.na(a)) return(unname(a)); c }

# ---- read frozen snapshot (row 1 = title, row 2 = header) --------------------
snap <- read_excel(file.path(folder, paste0(item_name, "_snapshot.xlsx")),
                   sheet = "TableS1_snapshot", skip = 1, .name_repair = "minimal")
snap <- as.data.frame(snap, check.names = FALSE)
snap <- snap[!is.na(snap$Species) & nzchar(trimws(snap$Species)), ]

# ---- correct the journal's header typos (documented in README) --------------
typo_fix <- c(Neuronal_denisty = "Neuronal_density",
              Glial_cell_denisty = "Glial_cell_density",
              Basal_metaboic_rate = "Basal_metabolic_rate")
nm <- names(snap); hit <- nm %in% names(typo_fix)
nm[hit] <- typo_fix[nm[hit]]; names(snap) <- nm

# ---- harmonise species (printed name kept as Species) -----------------------
df <- cbind(species_sci = vapply(snap$Species, resolve, character(1)),
            snap, stringsAsFactors = FALSE)

write.csv(df, file.path(folder, paste0(item_name, ".csv")),
          row.names = FALSE, fileEncoding = "UTF-8")

filecodes    <- read_excel("__ReadMe.xlsx", sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
tsv_dir <- "__Public/comparative-data/"
if (!is.na(item_encoded) && dir.exists(tsv_dir))
  write.table(df, paste0(tsv_dir, item_encoded, ".tsv"),
              sep = "\t", row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")

cat("Lewitus TableS1:", nrow(df), "species written\n")
