# Stephan, Bauchot & Andy 1970 - full reformat (Tables 1-6)  [ACTIVATED - values trusted as-is]
# "Data on Size of the Brain and of Various Brain Parts in Insectivores and Primates."
# In: The Primate Brain (Advances in Primatology vol 1), pp. 289-297. DeCasien ref 51.
#
# Tables 1-3 = body weight (g), brain weight (mg), total brain NET volume and the five
#   fundamental brain sections; Tables 4-6 = the seven telencephalon components (all mm3).
#
# Output: local CSV + TSV here, and the ISBN-named TSV in __Public/comparative-data/ that
# volumes_compiled.R requires (registry "Item encoded" = ISBN%3A0390672505_Tables1-6).
# The Primate Brain is a book (no DOI); ISBN 0390672505 -> ISBN%3A0390672505.
library(tidyverse)

## --- locate paths (portable: Rscript or RStudio) ---
.this <- tryCatch({
  a <- commandArgs(FALSE); f <- sub("^--file=", "", a[grepl("^--file=", a)])
  if (length(f) && nzchar(f[1])) normalizePath(f[1])
  else if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
    normalizePath(rstudioapi::getActiveDocumentContext()$path)
  else NA_character_
}, error = function(e) NA_character_)
folder         <- if (!is.na(.this)) dirname(.this) else getwd()
dataset_root   <- dirname(folder)
public_tsv_dir <- file.path(dataset_root, "__Public", "comparative-data")

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

## --- public TSV for the volume merge (ISBN-encoded; matches __ReadMe.xlsx + volumes_compiled.R) ---
item_encoded <- "ISBN%3A0390672505_Tables1-6"
dir.create(public_tsv_dir, recursive = TRUE, showWarnings = FALSE)
write.table(clean, file.path(public_tsv_dir, paste0(item_encoded, ".tsv")), sep = "\t", row.names = FALSE)
message("Wrote ", file.path(public_tsv_dir, paste0(item_encoded, ".tsv")))

# --- internal validation: telencephalon components should sum to the telencephalon total ---
chk <- clean %>%
  mutate(comp_sum = bulbus_olfactorius_mm3 + palaeocortex_plus_amygdala_mm3 + septum_mm3 +
                    striatum_mm3 + schizocortex_mm3 + hippocampus_mm3 + neocortex_mm3,
         pct = 100 * abs(comp_sum - telencephalon_mm3) / telencephalon_mm3)
message("Stephan 1970 Tables 1-6: ", nrow(clean), " species.")
message(sprintf("Telencephalon components-vs-total check: max |diff| = %.2f%%, median = %.3f%%",
                max(chk$pct, na.rm = TRUE), median(chk$pct, na.rm = TRUE)))
