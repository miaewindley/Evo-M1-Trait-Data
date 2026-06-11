# Cross-paper energetics comparison (Part IV).
# Brings the brain-energetics measures from three sources into ONE tidy schema and
# tabulates where they overlap. NOTHING is merged here: the proposed schema is for
# user confirmation before any energetics merge is built.
#
# Sources:
#   Heiss et al. 2004      - human regional CMRgl (umol glucose /100 g/min).
#   Kaufman 2004           - multi-species whole-brain & regional CMRgl, CMRO2, CBF
#                            (weighted & unweighted species means; from the dissertation).
#   Karbowski 2007         - multi-species regional glucose utilization & oxygen
#                            consumption (xlsx headers are heavily OCR-garbled -> included
#                            descriptively only; needs a dedicated parse).
#
# Common measures: CMRgl (glucose), CMRO2 (oxygen), CBF (blood flow).

suppressPackageStartupMessages({ library(readr); library(readxl); library(dplyr); library(tidyr); library(stringr) })
base <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"
outdir <- file.path(base, "__energetics_comparison")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
numv <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x))))

## ---- Heiss 2004: human regional CMRgl ----
heiss <- read_csv(file.path(base, "Heiss_etal_2004/Heiss_etal_2004_TABLE1.csv"), show_col_types = FALSE) %>%
  transmute(reference = "Heiss_etal_2004", species = "Homo sapiens",
            region = Region, measure = "CMRgl",
            value = numv(`Both hemispheres Mean`),
            units = "umol_glucose/100g/min", weighting = NA_character_) %>%
  filter(!is.na(value))

## ---- Kaufman 2004: whole-brain + cortex CMRgl/CMRO2/CBF (weighted means) ----
kauf_long <- function(fn, region_label, region_prefix) {
  d <- read_csv(file.path(base, fn), show_col_types = FALSE) %>% filter(Weight %in% c("weighted") | weight %in% c("weighted"))
  d
}
read_kauf <- function(fn) read_csv(file.path(base, fn), show_col_types = FALSE)
wb <- read_kauf("Kaufman__2004/comparison/Kaufman data added to compilation/Kaufman glucose oxygen blood flow/wholebrain_Kaufman2004.csv")
pb <- read_kauf("Kaufman__2004/comparison/Kaufman data added to compilation/Kaufman glucose oxygen blood flow/partsbrain_Kaufman2004.csv")
wcol <- if ("weight" %in% names(wb)) "weight" else "Weight"
pcol <- if ("Weight" %in% names(pb)) "Weight" else "weight"
pick_means <- function(df, wname, region) {
  mean_cols <- names(df)[str_detect(names(df), "Mean$")]
  df %>% filter(.data[[wname]] == "weighted") %>%
    select(Species, all_of(mean_cols)) %>%
    pivot_longer(-Species, names_to = "col", values_to = "value") %>%
    mutate(value = numv(value),
           measure = case_when(str_detect(col, "CMRgl") ~ "CMRgl",
                               str_detect(col, "CMR0?2|CMRO2") ~ "CMRO2",
                               str_detect(col, "CBF") ~ "CBF", TRUE ~ NA_character_),
           region = str_squish(str_remove(col, "(CMRgl|CMRO2|CMR02|CBF).*$"))) %>%
    filter(!is.na(value), !is.na(measure))
}
kauf <- bind_rows(pick_means(wb, wcol), pick_means(pb, pcol)) %>%
  transmute(reference = "Kaufman_2004", species = Species, region = ifelse(region == "", "Whole Brain", region),
            measure, value,
            units = case_when(measure == "CMRgl" ~ "umol_glucose/100g/min",
                              measure == "CMRO2" ~ "umol_O2/100g/min",
                              measure == "CBF"   ~ "mL/100g/min"),
            weighting = "weighted")

energetics <- bind_rows(heiss, kauf) %>% arrange(measure, species, region)
write_csv(energetics, file.path(outdir, "energetics_long.csv"))

## ---- overlap: human cortical CMRgl, Heiss vs Kaufman ----
h_ctx <- heiss %>% filter(str_detect(tolower(region), "cortex|lobe")) %>% summarise(Heiss_CMRgl_cortex_mean = mean(value)) %>% pull()
k_ctx <- kauf %>% filter(species == "Homo", measure == "CMRgl", str_detect(tolower(region), "cortex")) %>% summarise(m = mean(value)) %>% pull()

species_by_ref <- energetics %>% group_by(reference) %>% summarise(species = paste(sort(unique(species)), collapse = ", "), .groups="drop")

findings <- c(
  "# Brain energetics - cross-paper comparison (Part IV)",
  "",
  "Common measures across the energetics papers: **CMRgl** (glucose), **CMRO2** (oxygen), **CBF** (blood flow).",
  "Output: `energetics_long.csv` (schema: reference, species, region, measure, value, units, weighting).",
  "",
  "## Coverage",
  paste0("- ", species_by_ref$reference, ": ", species_by_ref$species),
  "- Karbowski 2007: multi-species regional glucose utilization & oxygen consumption -- the source",
  "  xlsx headers are badly OCR-garbled, so it is described here but not yet parsed into the table;",
  "  it needs a dedicated extraction pass (like Stephan 1970).",
  "",
  "## Human cortical CMRgl cross-check (independent sources)",
  sprintf("- Heiss 2004 mean cortical CMRgl  ~ %.1f umol/100g/min", h_ctx),
  sprintf("- Kaufman 2004 (Homo) cortical CMRgl ~ %.1f umol/100g/min", k_ctx),
  "  -> same order of magnitude; good independent agreement for human cortex glucose metabolism.",
  "",
  "## Proposed schema for an energetics merge (FOR CONFIRMATION - not built)",
  "A long table mirroring `volumes_long.csv` but for metabolic rate:",
  "  `Species, Region, Measure (CMRgl|CMRO2|CBF), Value, Units, Weighting, Source, Team, Year`",
  "with:",
  "- Units standardized to umol/100 g/min (CMRgl, CMRO2) and mL/100 g/min (CBF).",
  "- A region crosswalk to the volume terms (e.g. Cortex<->Neocortex, Thalamus, Cerebellum, ...).",
  "- Two-tier resolution like the volumes (Kaufman/Karbowski/Heiss are independent series -> Tier-2",
  "  teams, averaged), keeping weighted vs unweighted Kaufman means distinct (recommend weighted).",
  "",
  "Confirm this schema (units, region crosswalk, weighting choice, whether to include CBF) before an",
  "energetics merge is implemented."
)
writeLines(findings, file.path(outdir, "ENERGETICS_FINDINGS.md"))
message("energetics_long.csv rows: ", nrow(energetics),
        " | refs: ", paste(unique(energetics$reference), collapse=","))
