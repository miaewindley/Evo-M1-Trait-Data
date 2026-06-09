## MacLeod et al. 2003, J Hum Evol 44:401-429 — Table 2 (Hirnforschung sample)
## Snapshot -> clean. Per-specimen volumes (cm3): whole brain, cerebellum, vermis, hemispheres.
## Golden rule: the snapshot is frozen/faithful; ALL cleaning happens here.

setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/MacLeod_etal_2003")
options(scipen = 999)

raw <- read.csv("MacLeod_etal_2003_Table2_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
spec <- raw$Specimen

# Footnote markers carried in the Specimen cell (per the Table 2 legend):
#   †  from the Stephan Collection   ‡  brain weight not known
#   *  horizontal sections           §  sagittal sections   (default: coronal)
has_star <- grepl("*", spec, fixed = TRUE)
has_sec  <- grepl("§", spec, fixed = TRUE)
clean_species <- function(s) {
  s  <- gsub("[*†‡§]", "", s); s <- trimws(sub("\\(.*$", "", s)); tk <- strsplit(s, "\\s+")[[1]]
  out <- trimws(paste(tk[1], if (length(tk) >= 2) tk[2] else ""))
  if (length(tk) >= 3 && grepl("^[a-z]+$", tk[3])) out <- paste(out, tk[3]); out
}
as_num <- function(x) suppressWarnings(as.numeric(x))

clean <- data.frame(
  species               = vapply(spec, clean_species, character(1), USE.NAMES = FALSE),
  specimen              = trimws(gsub("\\s*[*†‡§]+", "", spec)),
  sex                   = raw$Sex,
  sample                = "Hirnforschung",
  brain_volume_cm3      = as_num(raw[["Brain volume cm3"]]),
  cerebellum_volume_cm3 = as_num(raw[["Cerebellum volume cm3"]]),
  vermis_volume_cm3     = as_num(raw[["Vermis volume cm3"]]),
  hemisphere_volume_cm3 = as_num(raw[["Hemisphere volume cm3"]]),
  stephan_collection    = grepl("†", spec, fixed = TRUE),
  section_plane         = ifelse(has_star & has_sec, "mixed", ifelse(has_star, "horizontal", ifelse(has_sec, "sagittal", "coronal"))),
  brainweight_known     = !grepl("‡", spec, fixed = TRUE),
  source                = "MacLeod_etal_2003",
  stringsAsFactors = FALSE
)
# Species still to reconcile to _keys/Stephan/species_key.csv (e.g. Cebus apella -> Sapajus apella).
write.csv(clean, "MacLeod_etal_2003_Table2.csv", row.names = FALSE)
