# Karbowski__2007_energetics_table_from_xlsx.R
#
# Stage 1 (energetics). Builds a tidy brain-region energetics table from the Karbowski
# (2007) supplementary data. There is no existing compilation CSV to check against
# (the "data added to compilation" folder holds only the raw xlsx), so this script
# BUILDS the first machine-readable extraction. Nothing is merged with other papers.
#
# Sources (Karbowski 2007 supplementary tables):
#   Karbowski data added to compilation/Karbowski glucose oxygen/
#       data and metadata brain glucose util.xlsx
#       data and metadata brain oxygen consumption Karbowski.xlsx
#
# Notes (verified): row 1 = title, row 2 = header, data from row 3 (skip 2). The
# glucose "umol/100g/min" block is empty; the populated whole-brain value is
# "Glucose utilization (umol/g/min)" (units differ from Kaufman: per g, not per 100g).
# Some cells combine mean and SD as "1.22 +/- 0.12". "x" = counts toward brain average
# (not a number). Continuation rows leave Species blank (forward-filled); "average
# <species>" rows are Karbowski's per-species summaries (flagged, not dropped).
# readxl can render small values as scientific notation -> the number parser keeps the
# exponent (else 0.034 would be read as 3.4).
#
# Output (into this comparison/ folder):
#   Karbowski__2007_energetics_long_from_R.csv

suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr) })
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Karbowski__2007/comparison")
}
}

gobf     <- file.path("Karbowski data added to compilation", "Karbowski glucose oxygen")
glu_file <- file.path(gobf, "data and metadata brain glucose util.xlsx")
oxy_file <- file.path(gobf, "data and metadata brain oxygen consumption Karbowski.xlsx")
out_long <- "Karbowski__2007_energetics_long_from_R.csv"

num_pat <- "-?[0-9]*\\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
extract_n <- function(x, i) {
  m <- str_extract_all(as.character(x), num_pat)
  vapply(m, function(v) if (length(v) >= i) suppressWarnings(as.numeric(v[i])) else NA_real_, numeric(1))
}
num1 <- function(x) extract_n(x, 1)
num2 <- function(x) extract_n(x, 2)
blank_na <- function(x) na_if(str_squish(as.character(x)), "")

gnames <- c("common","weighted","N","gl100_mean","gl100_sd","gl100_cv","gl100_cvstar",
            "wb_glu_mean","wb_glu_sd","wb_glu_total","pfc_glu","fc_glu","ref","ref_full",
            "link","common_paper","species_paper","species_bin","note","val_structures")
g <- read_excel(glu_file, sheet = 1, col_names = FALSE, skip = 2, col_types = "text",
                .name_repair = "minimal")
names(g)[seq_len(min(length(gnames), ncol(g)))] <- gnames[seq_len(min(length(gnames), ncol(g)))]
g <- g %>%
  mutate(common = blank_na(common), species_bin = blank_na(species_bin)) %>%
  filter(is.na(common) | !str_starts(common, "x =")) %>%
  filter(!(is.na(common) & is.na(ref) & is.na(wb_glu_mean) & is.na(wb_glu_total) &
           is.na(pfc_glu) & is.na(fc_glu))) %>%
  fill(common, species_bin, .direction = "down") %>%
  mutate(is_species_average = str_starts(coalesce(common, ""), "average "),
         species_common     = str_remove(common, "^average "))
meta_g <- function(d) d %>% transmute(
  source_file="glucose", species_common, is_species_average, species=species_bin,
  common_name_in_paper=common_paper, species_name_in_paper=species_paper,
  reference=ref, reference_full=ref_full, link, note, val_structures)
glu_long <- bind_rows(
  bind_cols(meta_g(g), tibble(region="Whole brain", measure="CMRgl", units="umol/g/min",
            value=num1(g$wb_glu_mean), sd=num1(g$wb_glu_sd))),
  bind_cols(meta_g(g), tibble(region="Whole brain", measure="Total_glucose_utilization",
            units="umol/min", value=num1(g$wb_glu_total), sd=NA_real_)),
  bind_cols(meta_g(g), tibble(region="Prefrontal cortex", measure="CMRgl", units="umol/g/min",
            value=num1(g$pfc_glu), sd=num2(g$pfc_glu))),
  bind_cols(meta_g(g), tibble(region="Frontal cortex", measure="CMRgl", units="umol/g/min",
            value=num1(g$fc_glu), sd=num2(g$fc_glu))))

onames <- c("common","o2_mean","o2_sd","o2_total","ref","ref_full","link",
            "common_paper","species_paper","species_bin","note","val_structures")
o <- read_excel(oxy_file, sheet = 1, col_names = FALSE, skip = 2, col_types = "text",
                .name_repair = "minimal")
names(o)[seq_len(min(length(onames), ncol(o)))] <- onames[seq_len(min(length(onames), ncol(o)))]
o <- o %>%
  mutate(common = blank_na(common), species_bin = blank_na(species_bin)) %>%
  filter(!(is.na(common) & is.na(o2_mean) & is.na(o2_total) & is.na(ref))) %>%
  fill(common, species_bin, .direction = "down") %>%
  mutate(is_species_average = str_starts(coalesce(common, ""), "average "),
         species_common     = str_remove(common, "^average "))
meta_o <- function(d) d %>% transmute(
  source_file="oxygen", species_common, is_species_average, species=species_bin,
  common_name_in_paper=common_paper, species_name_in_paper=species_paper,
  reference=ref, reference_full=ref_full, link, note, val_structures)
oxy_long <- bind_rows(
  bind_cols(meta_o(o), tibble(region="Whole brain", measure="CMRO2", units="ml/g/min",
            value=num1(o$o2_mean), sd=num1(o$o2_sd))),
  bind_cols(meta_o(o), tibble(region="Whole brain", measure="Total_oxygen_consumption",
            units="ml/min", value=num1(o$o2_total), sd=NA_real_)))

karb <- bind_rows(glu_long, oxy_long) %>%
  mutate(species = blank_na(species)) %>%
  filter(!is.na(value)) %>%
  relocate(source_file, species_common, species, is_species_average, region, measure, value, sd, units) %>%
  arrange(source_file, species_common, region, measure)
write_csv(karb, out_long)

message(nrow(karb), " energetics rows -> ", out_long)
message("species (binomial): ", n_distinct(karb$species[!is.na(karb$species)]),
        " | measures: ", paste(sort(unique(karb$measure)), collapse = ", "))
