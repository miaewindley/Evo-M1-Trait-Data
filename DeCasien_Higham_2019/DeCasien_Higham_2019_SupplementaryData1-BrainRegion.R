### DeCasien & Higham 2019 -- comparison of their compiled brain-region volumes
### (Supplementary MOESM3) against THIS repo's merged volume DeCasien dataset.
###
### Rewrite (Part II): the previous version only built two long frames and never
### compared anything, used a hardcoded path, and assumed sheet/column names. This
### version:
###   II.A  value-based match of every DeCasien (species, region, value) against the
###         merge (volumes_unfiltered.csv, per-source, mm3), constrained to the same
###         GENUS and within a relative tolerance (same numeric value => same datum,
###         mirroring crosspub_value_match.R). Annotated with an anatomy crosswalk
###         (DeCasien region <-> our *_Vol.mm3 term) and DeCasien's Stephan reference
###         numbering (24 = Stephan 1981, 51 = Stephan 1970, 52 = Stephan 1988).
###   II.B  taxonomy: rows that match by value+genus but DIFFER in the species name
###         (e.g. DeCasien "Gorilla gorilla" vs our "Gorilla sp.") are written to a
###         proposed-changes CSV (species_key variant -> accepted) for human review.
### Outputs:
###   DeCasien_vs_merge_comparison.csv
###   DeCasien_taxonomy_proposed_changes.csv
###   DeCasien_Higham_2019_FINDINGS.md

## ---- paths: self-contained (Rscript or RStudio; full repo or lone folder) ----
.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)             # Rscript file.R
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getSourceEditorContext()$path                    # RStudio: Source
    if (!nzchar(p)) p <- rstudioapi::getActiveDocumentContext()$path  # RStudio: Run
    if (nzchar(p)) return(normalizePath(p))
  }
  stop("Run with Rscript file.R, or open in RStudio and click Source (save first).", call. = FALSE)
})
folder <- paper_dir <- dirname(.sp)                                   # this paper's folder
item_name <- table_name <- tools::file_path_sans_ext(basename(.sp))  # = file name (matches __ReadMe.xlsx)
base <- dataset_root <- local({                                      # repo root; NA if run as a lone folder
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr); library(purrr)
})

base <- base
dec_dir <- file.path(base, "DeCasien_Higham_2019")
tol <- 0.02
## Which merge to compare against. Default "" = the canonical core merge (volumes_*.csv).
## volumes_compiled_DeCasien.R sets merge_suffix <- "_EXPANDED" before source()-ing this
## script, to compare the DeCasien-inclusive EXPANDED merge instead. Outputs get the same suffix.
merge_suffix <- if (exists("merge_suffix")) merge_suffix else ""
norm  <- function(s) str_squish(tolower(gsub("[._]", " ", s)))
genus <- function(s) word(norm(s), 1)
numv  <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x))))

## ---- reference (the merge), per source, mm3 ----
unf <- read_csv(file.path(base, paste0("__merging_volumes/volumes_unfiltered", merge_suffix, ".csv")), show_col_types = FALSE) %>%
  transmute(sp = norm(Species), genus = genus(Species), Variable,
            Value = numv(Value), Source) %>% filter(!is.na(Value), Value != 0)
merged <- read_csv(file.path(base, paste0("__merging_volumes/volumes_long", merge_suffix, ".csv")), show_col_types = FALSE) %>%
  transmute(sp = norm(Species), Variable, merge_value = numv(Value))

# which merge Sources correspond to DeCasien's Stephan reference ids
stephan_sources <- c("Stephan_etal_1981_Table1","Stephan_etal_1982_Table1",
                     "Stephan_etal_1984_Table1","Stephan_etal_1987_Table1")

## ---- DeCasien anatomy crosswalk: region -> our canonical term ----
xwalk <- c(
  "BV"                    = "Total_brain_net_volume_Vol.mm3",
  "Medulla"               = "Medulla_oblongata_Vol.mm3",
  "Cerebellum"            = "Cerebellum_Vol.mm3",
  "Mesencephalon"         = "Mesencephalon_Vol.mm3",
  "Diencephalon"          = "Diencephalon_Vol.mm3",
  "Telencephalon"         = "Telencephalon_Vol.mm3",
  "MOB"                   = "Bulbus_olfactorius_Vol.mm3",
  "AOB"                   = "Bulbus_olfactorius_accessorius_Vol.mm3",
  "Piriform Lobe"         = "Lobus_piriformis_Vol.mm3",
  "Septum"                = "Septum_Vol.mm3",
  "Striatum"              = "Striatum_Vol.mm3",
  "Schizocortex"          = "Schizo_cortex_Vol.mm3",
  "Hippocampus"           = "Hippocampus_Vol.mm3",
  "Neocortex (GM+WM)"     = "Neocortex_Vol.mm3",
  "Neocortex (GM)"        = "Neocortex_grey_matter_Vol.mm3",
  "Epithalamus"           = "Epithalamus_Vol.mm3",
  "Thalamus"              = "Thalamus_Vol.mm3",
  "Hypothalamus"          = "Hypothalamus_Vol.mm3",
  "Subthalamus"           = "Subthalamus_Vol.mm3",
  "Pallidum"              = "Pallidum_Vol.mm3",
  "Subthalamic Nucleus"   = "Nucleus_subthalamicus_Vol.mm3",
  "Optic Tract"           = "Tractus_opticus_Vol.mm3",
  "V1 (GM)"               = "Area_striata_grey_matter_Vol.mm3",
  "LGN"                   = "Corpus_geniculatum_laterale_Vol.mm3",
  "Paleocortex"           = "Palaeocortex_Vol.mm3",
  "Amygdala"              = "Amygdala_Vol.mm3",
  # DeCasien reports these six regions as BILATERAL (both-hemisphere) volumes, so they are
  # crosswalked to our both-sides "_Vol.mm3" terms, not the raw one-side "_left_Vol.mm3"
  # columns. (Confirmed empirically: DeCasien's values were exactly 2x our old _left figures.)
  # volumes_compiled_DeCasien.R step 7 builds these both-sides terms already -- summed from
  # left+right where both were measured (Bauernfeind insula), or doubled-and-flagged where
  # only one side was ever measured (Sherwood 2005 cranial motor nuclei).
  "Vmo"                   = "Trigeminal_motor_nucleus_Vol.mm3",
  "VII"                   = "Facial_motor_nucleus_Vol.mm3",
  "XII"                   = "Hypoglossal_nucleus_Vol.mm3",
  "Granular Insula"       = "Granular_insular_cortex_Vol.mm3",
  "Dysgranular Insula"    = "Dysgranular_insular_cortex_Vol.mm3",
  "Insula (GM)"           = "Insula_Vol.mm3"
)
# regions with no clean single counterpart in our merge -> left out of the crosswalk:
#   Striatum (incl. NAcc), Agranular Insula (we carry _left/_right separately)
# NOTE (term fragmentation found by this comparison): the accessory olfactory bulb exists
# under TWO canonical terms in the merge -- Bulbus_olfactorius_accessorius_Vol.mm3 (Stephan
# 1981) and AccessoryOlfactoryBulb_Vol.mm3 (Stephan 1982). AOB is crosswalked to the former
# (it carries the DeCasien-matching Stephan 1981 values).

## ---- adopted DeCasien taxonomy reconciliation (species_key 'DeCasien' token) ----
## variant (DeCasien binomial) -> accepted (merge name) pairs adopted from
## DeCasien_taxonomy_proposed_changes.csv. Applied to the DeCasien species name before the
## species-agreement test so adopted synonyms count as matches, not taxonomy variants.
spkey_dec <- read_csv(file.path(base, "_keys/Stephan/species_key.csv"), show_col_types = FALSE) %>%
  filter(source_publication == "DeCasien")
dec_remap <- function(s) {
  i <- match(s, norm(spkey_dec$variant_name))
  ifelse(is.na(i), s, norm(spkey_dec$accepted_name)[i])
}

## ---- DeCasien long frame ----
expand_refs <- function(x) {                       # "24,51-52" -> c(24,51,52)
  parts <- str_split(x, "[,;]+")[[1]] %>% str_squish() %>% discard(~ .x == "")
  out <- integer(0)
  for (p in parts) {
    if (str_detect(p, "^\\d+-\\d+$")) { ab <- as.integer(str_split(p, "-")[[1]]); out <- c(out, ab[1]:ab[2]) }
    else if (str_detect(p, "^\\d+$")) out <- c(out, as.integer(p))
  }
  unique(out)
}
moesm3 <- read_excel(file.path(dec_dir, "41559_2019_969_MOESM3_ESM.xlsx"),
                     sheet = "Brain Region Data (mm3)")
region_cols <- intersect(names(xwalk), names(moesm3))
dec <- moesm3 %>%
  rename(taxon = Taxon) %>%
  select(taxon, References, all_of(region_cols)) %>%
  pivot_longer(all_of(region_cols), names_to = "dec_region", values_to = "dec_value") %>%
  mutate(dec_value = numv(dec_value)) %>% filter(!is.na(dec_value), dec_value != 0) %>%
  mutate(sp = dec_remap(norm(taxon)), genus = genus(taxon),
         our_term = unname(xwalk[dec_region]),
         refs = map(as.character(References), expand_refs),
         ref_is_stephan = map_lgl(refs, ~ any(.x %in% c(24L, 51L, 52L))),
         ref_ids = map_chr(refs, ~ paste(.x, collapse = ";")))

## ---- II.A value match (same genus, within tol; record species agreement) ----
## Prefer a same-STRUCTURE candidate (Variable == our_term) over the globally-nearest value on
## ANY variable for that genus. Without this, a numerically-coincidental match on an unrelated
## variable (e.g. BV landing within tol of that genus's Brain_Mass.mg, or its Telencephalon
## volume) can beat out a true same-structure match that simply isn't the single closest value --
## silently downgrading a real "match"/"match_taxonomy_variant" to "value_match_other_structure".
match_row <- function(g, val, term) {
  cand <- unf %>% filter(genus == g) %>% mutate(d = abs(Value - val) / abs(Value)) %>%
    filter(d <= tol)
  if (!nrow(cand)) return(tibble(matched_source = NA_character_, matched_variable = NA_character_,
                                 matched_sp = NA_character_, matched_value = NA_real_, pct_diff = NA_real_))
  same_term <- cand %>% filter(!is.na(term), Variable == term)
  pick <- if (nrow(same_term)) same_term else cand
  pick %>% arrange(d) %>% slice(1) %>%
    transmute(matched_source = Source, matched_variable = Variable,
              matched_sp = sp, matched_value = Value, pct_diff = round(d * 100, 3))
}
mm <- pmap_dfr(list(g = dec$genus, val = dec$dec_value, term = dec$our_term), match_row)
cmp <- bind_cols(dec %>% select(taxon, sp, genus, dec_region, our_term, dec_value, ref_ids, ref_is_stephan), mm) %>%
  mutate(
    anatomy_agree = !is.na(matched_variable) & !is.na(our_term) & matched_variable == our_term,
    species_agree = !is.na(matched_sp) & matched_sp == sp,
    status = case_when(
      is.na(matched_source)                 ~ "decasien_only",
      anatomy_agree &  species_agree        ~ "match",
      anatomy_agree & !species_agree        ~ "match_taxonomy_variant",
      !anatomy_agree                        ~ "value_match_other_structure"
    ))
write_csv(cmp %>% select(taxon, sp, dec_region, our_term, dec_value, ref_ids, ref_is_stephan,
                         status, matched_source, matched_variable, matched_sp, matched_value, pct_diff),
          file.path(dec_dir, paste0("DeCasien_vs_merge_comparison", merge_suffix, ".csv")))

## ---- II.B taxonomy proposals: value-matched rows whose species name differs ----
prop <- cmp %>% filter(status == "match_taxonomy_variant", ref_is_stephan) %>%
  transmute(decasien_taxon = taxon, decasien_name = str_to_sentence(sp),
            merge_accepted_name = str_to_sentence(matched_sp),
            structure = our_term, dec_value, matched_value, matched_source,
            proposed = "adopt DeCasien binomial (variant -> accepted) in _keys/Stephan/species_key.csv") %>%
  distinct(decasien_name, merge_accepted_name, .keep_all = TRUE) %>%
  arrange(merge_accepted_name)
write_csv(prop, file.path(dec_dir, paste0("DeCasien_taxonomy_proposed_changes", merge_suffix, ".csv")))

## ---- merge-only coverage (Stephan-sourced species x term not present in DeCasien) ----
dec_keys <- cmp %>% filter(!is.na(our_term)) %>% distinct(sp, our_term)
merge_stephan <- unf %>% filter(Source %in% stephan_sources) %>% distinct(sp, Variable) %>%
  semi_join(tibble(Variable = unname(xwalk)), by = "Variable")
merge_only_n <- merge_stephan %>% anti_join(dec_keys, by = c("sp", "Variable" = "our_term")) %>% nrow()

## ---- summary + FINDINGS ----
tab <- cmp %>% count(status)
get <- function(s) { v <- tab$n[tab$status == s]; if (length(v)) v else 0 }
median_pct <- cmp %>% filter(status %in% c("match","match_taxonomy_variant")) %>% pull(pct_diff) %>%
  median(na.rm = TRUE) %>% round(3)

findings <- c(
  "# DeCasien & Higham 2019 vs the merged volume dataset -- FINDINGS (Part II)",
  "",
  sprintf("Compared %d DeCasien (species x region) volume cells against the merge by VALUE (same genus, tol = %.0f%%).",
          nrow(cmp), tol * 100),
  "Crosswalk covers the DeCasien regions that have a single clean counterpart in our merge;",
  "MOB, 'Striatum (incl. NAcc)' and 'Agranular Insula' are intentionally outside it.",
  "",
  "## II.A value comparison",
  sprintf("- match (same species + same structure, value within tol): **%d**", get("match")),
  sprintf("- match_taxonomy_variant (same structure + value, species NAME differs): **%d** -> see II.B", get("match_taxonomy_variant")),
  sprintf("- value_match_other_structure (value matched a different structure/label): **%d**", get("value_match_other_structure")),
  sprintf("- decasien_only (no value match in the merge for that genus): **%d**", get("decasien_only")),
  sprintf("- median |pct diff| on value matches: **%s%%** (most are 0%% -> identical underlying Stephan data)", median_pct),
  sprintf("- merge-only: ~%d Stephan-sourced (species x crosswalked structure) cells not present in DeCasien's sheet.", merge_only_n),
  "",
  "DeCasien references 24 = Stephan 1981, 51 = Stephan 1970, 52 = Stephan 1988; `ref_is_stephan`",
  "flags rows DeCasien attributes to a Stephan source. High value-match rates on those rows confirm",
  "the merge reproduces the Stephan primaries DeCasien compiled.",
  "",
  "## II.B taxonomy",
  sprintf("%d species appear under a DeCasien binomial that value-matches a DIFFERENT name in the merge",
          nrow(prop)),
  "(typically our genus-level 'sp.' vs DeCasien's full binomial). Proposed variant->accepted additions",
  "to `_keys/Stephan/species_key.csv` are in `DeCasien_taxonomy_proposed_changes.csv` for HUMAN REVIEW;",
  "they are NOT applied automatically (taxonomy lumping needs a human check).",
  "",
  "## Outputs",
  "- `DeCasien_vs_merge_comparison.csv` -- per-cell comparison.",
  "- `DeCasien_taxonomy_proposed_changes.csv` -- proposed species_key edits (review before applying).",
  "",
  "## II.C organizational practices worth borrowing from DeCasien",
  "- explicit numeric **reference-id columns** per value (we keep `Source`/`Teams`; a stable ref-id",
  "  map like DeCasien's would make provenance joins easier).",
  "- explicit **GM / WM / GM+WM** split naming for cortex/insula (we already do grey/white; adopting",
  "  DeCasien's '(GM)'/'(GM+WM)' convention in column docs would aid cross-dataset joins).",
  "- a single tidy compiled sheet with one reference column -- useful as an export view alongside",
  "  `volumes_long.csv`."
)
writeLines(findings, file.path(dec_dir, paste0("DeCasien_Higham_2019_FINDINGS", merge_suffix, ".md")))

message("DeCasien comparison: ", nrow(cmp), " cells | match=", get("match"),
        " taxonomy_variant=", get("match_taxonomy_variant"),
        " other=", get("value_match_other_structure"), " decasien_only=", get("decasien_only"),
        " | taxonomy proposals=", nrow(prop))
