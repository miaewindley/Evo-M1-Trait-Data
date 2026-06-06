## MacLeod et al. 2003, J Hum Evol 44:401-429 — "Expansion of the neocerebellum in Hominoidea"
## Snapshot -> clean. Tables 1 (Yerkes) and 2 (Hirnforschung): per-specimen volumes (cm3) of
## whole brain, cerebellum, cerebellar vermis, cerebellar hemispheres.
## Golden rule: snapshots are frozen/faithful; ALL cleaning happens here.

setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/MacLeod_etal_2003")
options(scipen = 999)

# 1. Read the two faithful snapshots (headers kept as published; check.names=FALSE)
t1 <- read.csv("MacLeod_etal_2003_Table1_Yerkes_snapshot.csv",        check.names = FALSE, stringsAsFactors = FALSE)
t2 <- read.csv("MacLeod_etal_2003_Table2_Hirnforschung_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
t1$sample <- "Yerkes"
t2$sample <- "Hirnforschung"
raw <- rbind(t1, t2)

# 2. Footnote markers carried in the Specimen cell (per the published legend):
#      †  specimen from the Stephan Collection
#      ‡  post-mortem brain weight not known
#      *  horizontal sections   §  sagittal sections   (default: coronal)
spec <- raw$Specimen
stephan_collection <- grepl("†", spec, fixed = TRUE)   # †
brainweight_known  <- !grepl("‡", spec, fixed = TRUE)  # ‡
has_star <- grepl("*", spec, fixed = TRUE)                  # *
has_sec  <- grepl("§", spec, fixed = TRUE)             # §
section_plane <- ifelse(has_star & has_sec, "mixed",
                 ifelse(has_star, "horizontal",
                 ifelse(has_sec,  "sagittal", "coronal")))

# 3. Clean species binomial (strip markers + the individual ID in parentheses;
#    keep a 3rd token only if it is a lowercase subspecies epithet, e.g. "atys").
clean_species <- function(s) {
  s <- gsub("[*†‡§]", "", s)
  s <- trimws(sub("\\(.*$", "", s))
  tk <- strsplit(s, "\\s+")[[1]]
  out <- trimws(paste(tk[1], if (length(tk) >= 2) tk[2] else ""))
  if (length(tk) >= 3 && grepl("^[a-z]+$", tk[3])) out <- paste(out, tk[3])
  out
}
species  <- vapply(spec, clean_species, character(1), USE.NAMES = FALSE)
specimen <- trimws(gsub("\\s*[*†‡§]+", "", spec))

# 4. Volumes -> numeric ("NA" as printed becomes NA)
as_num <- function(x) suppressWarnings(as.numeric(x))
clean <- data.frame(
  species,
  specimen,
  sex                   = raw$Sex,
  sample                = raw$sample,
  brain_volume_cm3      = as_num(raw[["Brain volume cm3"]]),
  cerebellum_volume_cm3 = as_num(raw[["Cerebellum volume cm3"]]),
  vermis_volume_cm3     = as_num(raw[["Vermis volume cm3"]]),
  hemisphere_volume_cm3 = as_num(raw[["Hemisphere volume cm3"]]),
  stephan_collection,
  section_plane,
  brainweight_known,
  source = "MacLeod_etal_2003",
  stringsAsFactors = FALSE
)

# NB species names still need reconciliation to _keys/Stephan/species_key.csv
#    (e.g. Cebus apella -> Sapajus apella; "Cebus sp."/"Cercopithecus sp." unresolved).

write.csv(clean, "MacLeod_etal_2003.csv", row.names = FALSE)

# 5. Species means (merge-ready: this is what joins to the species-level Stephan table)
agg <- function(v) if (all(is.na(v))) NA_real_ else round(mean(v, na.rm = TRUE), 3)
sp <- split(clean, clean$species)
means <- do.call(rbind, lapply(names(sp), function(s) {
  d <- sp[[s]]
  data.frame(species = s, n = nrow(d),
             n_stephan_collection = sum(d$stephan_collection),
             brain_volume_cm3      = agg(d$brain_volume_cm3),
             cerebellum_volume_cm3 = agg(d$cerebellum_volume_cm3),
             vermis_volume_cm3     = agg(d$vermis_volume_cm3),
             hemisphere_volume_cm3 = agg(d$hemisphere_volume_cm3))
}))
write.csv(means, "MacLeod_etal_2003_species_means.csv", row.names = FALSE)
