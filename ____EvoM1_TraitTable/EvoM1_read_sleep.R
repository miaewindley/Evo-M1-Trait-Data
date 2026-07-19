# EvoM1: sleep (REM proportion + daily sleep duration) -> sleep.xlsx for the trait table.
# Reads the compiled merge (__merging_sleep/sleep_wide.csv), not a single source TSV, because the
# two sleep traits come from different papers (Eagleman & Vaughn 2021 = REM%, Herculano-Houzel 2015
# = daily sleep). Emits per-cell *_Source columns so build_data.R credits each value to its own
# primary reference. Correlatable side-by-side with the other trait tables on species_sci.
library(readxl); library(writexl)
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/")
folder_path <- "./____EvoM1_TraitTable/"

d <- read.csv("./__merging_sleep/sleep_wide.csv", stringsAsFactors = FALSE, check.names = FALSE)

# Species key: sleep_wide$Species is the accepted binomial (Eagleman common names already resolved
# via __merging_sleep/species_resolution_Eagleman.csv). Keep genus-level "<Genus> sp." labels as-is.
fmt <- function(x) ifelse(is.na(x) | x == "", NA,
                          ifelse(x == round(x), as.character(as.integer(x)), as.character(x)))

out <- data.frame(
  species_sci          = d$Species,
  Species              = d$Species,
  REM_sleep_pct        = fmt(d$REM_sleep_pct),
  REM_sleep_pct_Source = ifelse(is.na(d$REM_sleep_pct), NA, "Eagleman & Vaughn 2021 (REM sleep)"),
  Sleep_h_day          = fmt(d$Sleep_h_day),
  Sleep_h_day_Source   = ifelse(is.na(d$Sleep_h_day),   NA, "Herculano-Houzel 2015 (daily sleep)"),
  stringsAsFactors = FALSE, check.names = FALSE)

write_xlsx(out, paste0(folder_path, "sleep.xlsx"))
cat("sleep.xlsx:", nrow(out), "rows (",
    sum(!is.na(out$REM_sleep_pct)), "REM,",
    sum(!is.na(out$Sleep_h_day)), "daily-sleep )\n")
