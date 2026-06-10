## Ashwell K (2020), Zoology 142:125753.  "Quantitative analysis of the cerebellum
## in monotremes, marsupials and placental mammals."  Supplementary table:
## cerebellar (and related) volumes / surface areas per species.
## Snapshot -> clean.  Golden rule: the snapshot is frozen/faithful; cleaning happens here.

setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Ashwell__2020")
options(scipen = 999)

suppressPackageStartupMessages({ library(readxl); library(dplyr); library(stringr) })

raw <- read_excel("Ashwell__2020_SupplementaryTable_snapshot.xlsx", col_types = "text")

# The snapshot keeps the printed column headers (units, spaces). Rename to the
# snake_case codes used in Ashwell__2020_definitions.csv and the merge term map.
clean_names <- c(
  "group", "species", "common_name", "brain_volume_mm3", "total_cb_volume_mm3",
  "vermis_excl_cb10_mm3", "hemisphere_excl_fl_mm3", "flocculo_nodular_cb_cx_mm3",
  "ratio_hemisph_vermis", "total_cb_cx_volume_mm3", "cb_white_matter_mm3",
  "pn_rttg_volume_mm3", "deep_cb_nu_volume_mm3", "cb_ext_surface_esa_mm2",
  "cb_pial_surface_psa_mm2", "foliation_index")
stopifnot(ncol(raw) == length(clean_names))
names(raw) <- clean_names

num <- function(x) suppressWarnings(as.numeric(gsub(",", "", trimws(as.character(x)))))
numeric_cols <- clean_names[4:16]

# Drop the printed per-genus summary rows ("... mean" / "... SD"); strip the trailing
# specimen number (e.g. "Ornithorhynchus anatinus 1") so the few per-specimen monotreme
# rows collapse to one species mean. All other species are already one row each.
n_in <- nrow(raw)
dat <- raw %>%
  filter(!str_detect(species, regex("\\b(mean|SD)\\b", ignore_case = TRUE))) %>%
  mutate(species = str_squish(str_replace(species, "\\s+\\d+$", "")),
         across(all_of(numeric_cols), num))
n_summary_dropped <- n_in - nrow(dat)

clean <- dat %>%
  group_by(species) %>%
  summarise(group = first(group), common_name = first(common_name),
            across(all_of(numeric_cols), ~ mean(.x, na.rm = TRUE)), .groups = "drop") %>%
  mutate(across(all_of(numeric_cols), ~ ifelse(is.nan(.x), NA_real_, .x)),
         source = "Ashwell__2020") %>%
  relocate(group, species, common_name)

message("Ashwell: ", n_in, " snapshot rows -> ", nrow(clean), " species (",
        n_summary_dropped, " mean/SD summary rows dropped)")
write.csv(clean, "Ashwell__2020_SupplementaryTable.csv", row.names = FALSE)

## ---- also write the DOI-coded TSV to __Public/comparative-data/ (consumed by __merging_volumes) ----
item_name <- "Ashwell__2020_SupplementaryTable"
base      <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"
tsv_dir   <- file.path(base, "__Public/comparative-data")
filecodes <- readxl::read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
enc <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
if (is.na(enc) || !nzchar(enc)) {
  warning("No 'Item encoded' for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  write.table(clean, file = file.path(tsv_dir, paste0(enc, ".tsv")), sep = "\t", row.names = FALSE)
  message("Wrote ", file.path(tsv_dir, paste0(enc, ".tsv")))
}
