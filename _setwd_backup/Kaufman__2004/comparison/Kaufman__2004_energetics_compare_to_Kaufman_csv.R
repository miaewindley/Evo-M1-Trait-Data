# Kaufman__2004_energetics_compare_to_Kaufman_csv.R
#
# Stage 1 (energetics). Builds a tidy brain-region energetics table from the Kaufman
# (2004) dissertation extraction and audits it against the one-row-per-species
# compilation table in the same folder. NOTHING is merged across papers here -- this
# only verifies the Kaufman extraction is self-consistent (per the request: build the
# per-paper tables first; merging/comparison across datasets comes later).
#
# SOURCE (wide, one row per Species x weighting):
#   Kaufman data added to compilation/Kaufman glucose oxygen blood flow/
#       wholebrain_Kaufman2004.csv   (Whole Brain, all measures)
#       partsbrain_Kaufman2004.csv   (Cortex + 13 cortical/subcortical regions)
# COMPILATION (one row per species, binomial names, both weightings flattened):
#   Kaufman data added to compilation/Kaufman_energetics_weights.csv
#
# Measures: CMRgl (glucose), CMRO2 (oxygen), CBF (blood flow).
#   Units: CMRgl & CMRO2 in umol/100g/min ; CBF in mL/100g/min (per the dissertation
#   "data explaination.txt"). The source spells oxygen "CMR02" (zero) in most columns
#   and "CMRO2" (letter O) for Occipital Cortex -- both normalized to CMRO2.
#
# Outputs (into this comparison/ folder):
#   Kaufman__2004_energetics_long_from_R.csv          - the tidy table built here
#   Kaufman__2004_energetics_comparison_report_from_R.csv
#   Kaufman__2004_energetics_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({ library(readr); library(dplyr); library(tidyr); library(stringr) })
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/Kaufman__2004/comparison")
}

added   <- "Kaufman data added to compilation"
gobf    <- file.path(added, "Kaufman glucose oxygen blood flow")
wb_file <- file.path(gobf, "wholebrain_Kaufman2004.csv")
pb_file <- file.path(gobf, "partsbrain_Kaufman2004.csv")
cp_file <- file.path(added, "Kaufman_energetics_weights.csv")

out_long       <- "Kaufman__2004_energetics_long_from_R.csv"
out_report     <- "Kaufman__2004_energetics_comparison_report_from_R.csv"
out_mismatches <- "Kaufman__2004_energetics_comparison_mismatches_from_R.csv"

num <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x))))

# Kaufman genus label (source) -> binomial used in the compilation table.
# NOTE: Kaufman labels the rabbit "Lepus"; the compilation reconciles it to
# Oryctolagus_cuniculus. Macaca is kept genus-level on both sides ("Macaca (Genus)").
genus_to_binomial <- c(
  "Canis"="Canis_familiaris","Capra"="Capra_aegagrus","Equus"="Equus_caballus",
  "Felis"="Felis_catus","Homo"="Homo_sapiens","Lepus"="Oryctolagus_cuniculus",
  "Macaca"="Macaca (Genus)","Meriones"="Meriones_unguiculatus","Mus"="Mus_musculus",
  "Ovis"="Ovis_aries","Rattus"="Rattus_norvegicus","Sus"="Sus_scrofa_domesticus")

canon_stat <- function(s) dplyr::recode(s,
  "Std. Deviation"="SD", "Std..Deviation"="SD", "CV_unbiased"="CVstar", .default = s)
canon_measure <- function(m) ifelse(m == "CMR02", "CMRO2", m)
units_for     <- function(m) ifelse(m == "CBF", "mL/100g/min", "umol/100g/min")

read_source <- function(path) {
  d <- read_csv(path, show_col_types = FALSE, col_types = cols(.default = col_character()))
  wcol <- names(d)[tolower(names(d)) == "weight"][1]
  d %>%
    rename(weighting = all_of(wcol)) %>%
    select(-any_of("Speciesweight")) %>%
    pivot_longer(-c(Species, weighting), names_to = "col", values_to = "value") %>%
    mutate(
      stat_raw = str_match(col, "\\s+(N|Mean|Std\\. Deviation|CV_unbiased|CV)$")[, 2],
      rest     = str_remove(col, "\\s+(N|Mean|Std\\. Deviation|CV_unbiased|CV)$"),
      measure  = str_match(rest, "\\s+(CMRgl|CMRO2|CMR02|CBF)$")[, 2],
      region   = str_squish(str_remove(rest, "\\s+(CMRgl|CMRO2|CMR02|CBF)$"))
    ) %>%
    select(Species, weighting, region, measure, stat_raw, value)
}

source_long <- bind_rows(read_source(wb_file), read_source(pb_file)) %>%
  filter(!is.na(stat_raw), !is.na(measure)) %>%
  mutate(
    weighting        = tolower(str_squish(weighting)),
    measure          = canon_measure(measure),
    stat             = canon_stat(stat_raw),
    Species_binomial = recode(Species, !!!genus_to_binomial, .default = Species),
    units            = units_for(measure),
    value            = num(value))

tidy_tbl <- source_long %>%
  select(Species_binomial, Kaufman_genus = Species, weighting, region, measure, units, stat, value) %>%
  pivot_wider(names_from = stat, values_from = value) %>%
  relocate(Species_binomial, Kaufman_genus, weighting, region, measure, units,
           any_of(c("N", "Mean", "SD", "CV", "CVstar"))) %>%
  arrange(Species_binomial, weighting, region, measure)
write_csv(tidy_tbl, out_long)

comp_raw <- read_csv(cp_file, show_col_types = FALSE, col_types = cols(.default = col_character()))
comp_long <- comp_raw %>%
  select(-any_of("Kaufman.Species")) %>%
  pivot_longer(-Species, names_to = "col", values_to = "value") %>%
  mutate(
    weighting = str_match(col, "\\.(weighted|unweighted)$")[, 2],
    r1        = str_remove(col, "\\.(weighted|unweighted)$"),
    stat_raw  = str_match(r1, "\\.(N|Mean|Std\\.\\.Deviation|CV_unbiased|CV)$")[, 2],
    r2        = str_remove(r1, "\\.(N|Mean|Std\\.\\.Deviation|CV_unbiased|CV)$"),
    measure   = str_match(r2, "\\.(CMRgl|CMRO2|CMR02|CBF)$")[, 2],
    region    = str_squish(str_replace_all(str_remove(r2, "\\.(CMRgl|CMRO2|CMR02|CBF)$"), "\\.", " "))
  ) %>%
  filter(!is.na(stat_raw), !is.na(measure)) %>%
  transmute(Species_binomial = Species, weighting, region,
            measure = canon_measure(measure), stat = canon_stat(stat_raw), value = num(value))

keys <- c("Species_binomial", "weighting", "region", "measure", "stat")
src_cmp <- source_long %>% filter(stat %in% c("Mean", "N")) %>%
  transmute(across(all_of(keys)), value_src = value, in_src = TRUE)
cmp_cmp <- comp_long %>% filter(stat %in% c("Mean", "N")) %>%
  transmute(across(all_of(keys)), value_comp = value, in_comp = TRUE)

report <- full_join(src_cmp, cmp_cmp, by = keys) %>%
  mutate(
    in_src = coalesce(in_src, FALSE), in_comp = coalesce(in_comp, FALSE),
    real_src = in_src & !is.na(value_src), real_cmp = in_comp & !is.na(value_comp),
    tol = ifelse(stat == "N", 0, 0.05),
    match = case_when(!real_src & !real_cmp ~ TRUE,
                      real_src & real_cmp ~ abs(value_src - value_comp) <= tol, TRUE ~ FALSE),
    status = case_when(real_src & real_cmp ~ "compared", real_src ~ "source_only_value",
                       real_cmp ~ "compilation_only_value", TRUE ~ "both_absent")) %>%
  arrange(Species_binomial, region, measure, weighting, stat) %>%
  relocate(status, match, Species_binomial, weighting, region, measure, stat, value_src, value_comp)

write_csv(report, out_report)
write_csv(filter(report, !match), out_mismatches)

message(nrow(tidy_tbl), " tidy rows -> ", out_long)
message("compared cells: ", sum(report$status == "compared"),
        " | value mismatches: ", sum(!report$match),
        " | source-only: ", sum(report$status == "source_only_value"),
        " | compilation-only: ", sum(report$status == "compilation_only_value"))
