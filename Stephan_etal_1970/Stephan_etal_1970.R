# Stephan, Bauchot & Andy 1970 - full reformat (Tables 1-6)  [ACTIVATED - values trusted as-is]
# "Data on Size of the Brain and of Various Brain Parts in Insectivores and Primates."
# In: The Primate Brain (Advances in Primatology vol 1), pp. 289-297. DeCasien ref 51.
#
# Tables 1-3 = body weight (g), brain weight (mg), total brain NET volume and the five
#   fundamental brain sections (Medulla, Cerebellum, Mesencephalon, Diencephalon,
#   Telencephalon), in mm3, for Insectivores / Prosimians / Simians.
# Tables 4-6 = the seven telencephalon COMPONENTS (Bulbus olfactorius, Palaeocortex+NA,
#   Septum, Striatum, Schizocortex, Hippocampus, Neocortex), in mm3, same species.
#
# Both snapshots were transcribed from the high-resolution page renders (the embedded PDF
# text layer and the figshare xlsx are corrupted OCR). Promoted to non-DRAFT snapshots and
# activated into the volume merge (run 3); the _DRAFT.csv copies are kept for provenance.
script_path   <- rstudioapi::getActiveDocumentContext()$path
paper_dir     <- dirname(script_path)
dataset_root  <- dirname(paper_dir)
table_name    <- tools::file_path_sans_ext(basename(script_path))

# outputs
snapshot_xlsx  <- file.path(paper_dir, paste0(table_name, "_snapshot.xlsx"))
final_csv     <- file.path(paper_dir, paste0(table_name, ".csv"))
readme_xlsx   <- file.path(dataset_root, "__ReadMe.xlsx")
public_tsv_dir<- file.path(dataset_root, "__Public", "comparative-data")

library(tidyverse)
base <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"
folder <- file.path(base, "Stephan_etal_1970")

t13 <- read_csv(file.path(folder, "Stephan_etal_1970_Tables1-3_snapshot.csv"), show_col_types = FALSE)
t46 <- read_csv(file.path(folder, "Stephan_etal_1970_Tables4-6_snapshot.csv"), show_col_types = FALSE)

clean <- t13 %>%
  left_join(t46 %>% select(-group), by = c("id", "species")) %>%
  transmute(species,
            body_weight_g, brain_weight_mg, total_brain_net_mm3,
            medulla_oblongata_mm3, cerebellum_mm3, mesencephalon_mm3,
            diencephalon_mm3, telencephalon_mm3,
            bulbus_olfactorius_mm3, palaeocortex_plus_amygdala_mm3, septum_mm3,
            striatum_mm3, schizocortex_mm3, hippocampus_mm3, neocortex_mm3,
            source = "Stephan_etal_1970")

write_csv(clean, file.path(folder, "Stephan_etal_1970_Tables1-6.csv"))
write_tsv(clean, file.path(folder, "Stephan_etal_1970_Tables1-6.tsv"))

# --- internal validation: telencephalon components should sum to the telencephalon total ---
chk <- clean %>%
  mutate(comp_sum = bulbus_olfactorius_mm3 + palaeocortex_plus_amygdala_mm3 + septum_mm3 +
                    striatum_mm3 + schizocortex_mm3 + hippocampus_mm3 + neocortex_mm3,
         pct = 100 * abs(comp_sum - telencephalon_mm3) / telencephalon_mm3)
message("Stephan 1970 Tables 1-6: ", nrow(clean), " species.")
message(sprintf("Telencephalon components-vs-total check: max |diff| = %.2f%%, median = %.3f%% (n>1%%: %d)",
                max(chk$pct, na.rm = TRUE), median(chk$pct, na.rm = TRUE), sum(chk$pct > 1, na.rm = TRUE)))
bad <- chk %>% filter(pct > 1) %>% select(species, telencephalon_mm3, comp_sum, pct)
if (nrow(bad)) { message("Rows >1% (verify these):"); print(as.data.frame(round_df <- bad %>% mutate(pct = round(pct,2)))) }


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

