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

## Supplement `unf` with PER-SOURCE bilateral (both-hemisphere) reconstructions, for the six
## structures the crosswalk below expects as both-sides "_Vol.mm3" terms. volumes_unfiltered*.csv
## is written in volumes_compiled_DeCasien.R BEFORE its step 7 builds those both-sides terms (step
## 7 only appends them to volumes_long/volumes_wide), so without this, repointing the xwalk at
## "_Vol.mm3" finds zero candidates and silently falls back to decasien_only/wrong-structure --
## confirmed empirically: after first repointing the xwalk, Vmo/VII/XII/insula decasien_only
## counts were unchanged. This mirrors that step-7 logic (left+right -> sum; one side only -> 2x
## estimate) but per SOURCE, not team-merged, so matching still validates a single primary
## paper's own number (Bauernfeind insula: Table 1 left + Table 2 right, different Sources, joined
## by species; Sherwood 2005 cranial nuclei: left-only -> doubled). volumes_unfiltered*.csv on
## disk is untouched -- this exists only in this script's in-memory `unf`.
bilateral_terms <- c("Granular_insular_cortex", "Dysgranular_insular_cortex", "Insula",
                     "Trigeminal_motor_nucleus", "Facial_motor_nucleus", "Hypoglossal_nucleus")
lr <- unf %>%
  filter(Variable %in% paste0(rep(bilateral_terms, each = 2), c("_left_Vol.mm3", "_right_Vol.mm3"))) %>%
  mutate(side = if_else(str_ends(Variable, "_left_Vol.mm3"), "left", "right"),
         stem = str_remove(Variable, "_(left|right)_Vol\\.mm3$"))
unf_bilat <- lr %>%
  group_by(sp, genus, stem) %>%
  summarise(Value  = if (n_distinct(side) == 2) sum(Value) else 2 * Value[1],
            Source = paste0(paste(sort(unique(Source)), collapse = "+"), "_bilateral_est"),
            .groups = "drop") %>%
  transmute(sp, genus, Variable = paste0(stem, "_Vol.mm3"), Value, Source)
unf <- bind_rows(unf, unf_bilat)

## ---- PER-SPECIMEN supplement -------------------------------------------------------------------
## DeCasien's MOESM3 sheet is per-SPECIMEN (one row per brain); volumes_unfiltered stores species
## MEANS. For the papers DeCasien did NOT pre-average, a species mean can never equal an individual
## brain's value (except where a species has one specimen), so those cells were falling to
## decasien_only. Here we rebuild the per-specimen values straight from the primary TSVs (NO species
## aggregation), applying the SAME unit / bilateral conversions used in volumes_compiled_DeCasien.R,
## so every DeCasien brain can match its own source row. Added to `unf` as extra candidates; the
## species-mean rows stay, and match_row() still prefers the closest same-structure value.
## NOT reconstructable (repo holds only a species mean, not per-brain data): Barks 2014 (Gorilla
## beringei, ref 65) -- only its Fig-4A mean is on disk.
rd_cd <- function(enc) tryCatch(
  read.table(file.path(base, "__Public/comparative-data", paste0(enc, ".tsv")),
             header = TRUE, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE),
  error = function(e) NULL)
spec <- list()
addspec <- function(sp, Variable, Value, Source) {
  ok <- !is.na(Value) & !is.na(sp)
  if (any(ok)) spec[[length(spec) + 1L]] <<-
      tibble(sp = norm(sp[ok]), genus = genus(sp[ok]), Variable = Variable,
             Value = as.numeric(Value[ok]), Source = Source)
}
# Bauernfeind Table1(left)+Table2(right): per-specimen bilateral insula (L+R, or 2L if no right side);
# join Table2 by specimen id with the trailing a/b hemisphere-set letter stripped. Already mm3.
b1 <- rd_cd("10.1016%2Fj.jhevol.2012.12.003_Table1")
b2 <- rd_cd("10.1016%2Fj.jhevol.2012.12.003_Table2")
if (!is.null(b1) && !is.null(b2)) {
  bid  <- function(x) sub("[ab]$", "", trimws(as.character(x)))
  b2i  <- b2[match(bid(b1$Individual), bid(b2$Individual)), , drop = FALSE]
  for (sc in list(c("granular", "Granular_insular_cortex_Vol.mm3"),
                  c("dysgranular", "Dysgranular_insular_cortex_Vol.mm3"),
                  c("agranular", "Agranular_insular_cortex_Vol.mm3"),
                  c("total_insula", "Insula_Vol.mm3"))) {
    L <- numv(b1[[paste0(sc[1], "_L_mm3")]]); R <- numv(b2i[[paste0(sc[1], "_R_mm3")]])
    val <- ifelse(!is.na(L) & !is.na(R), L + R, ifelse(!is.na(L), 2 * L, NA_real_))
    addspec(b1$Species, sc[2], val, "Bauernfeind_T1T2_specimen")
  }
  addspec(b1$Species, "Total_brain_net_volume_Vol.mm3", numv(b1$brain_volume_mm3), "Bauernfeind_specimen")
}
# MacLeod Table1 (Yerkes) + Table2 (Hirnforschung): per-specimen brain / cerebellum, cm3 -> mm3
for (enc in c("10.1016%2Fs0047-2484(03)00028-9_Table1", "10.1016%2Fs0047-2484(03)00028-9_Table2")) {
  m <- rd_cd(enc); if (is.null(m)) next
  addspec(m$species, "Total_brain_net_volume_Vol.mm3", numv(m$brain_volume_cm3) * 1000, "MacLeod_specimen")
  addspec(m$species, "Cerebellum_Vol.mm3",             numv(m$cerebellum_volume_cm3) * 1000, "MacLeod_specimen")
}
# Barger 2014: per-specimen ONE-hemisphere cc -> x2 (both sides) -> mm3
bg14 <- rd_cd("10.3389%2Ffnhum.2014.00277_Table1")
if (!is.null(bg14)) {
  addspec(bg14$species, "Amygdala_Vol.mm3",    numv(bg14$amygdala_total_cc) * 2000, "Barger2014_specimen")
  addspec(bg14$species, "Hippocampus_Vol.mm3", numv(bg14$hippocampus_cc)    * 2000, "Barger2014_specimen")
  addspec(bg14$species, "Striatum_Vol.mm3",    numv(bg14$striatum_cc)       * 2000, "Barger2014_specimen")
}
# Barger 2007: per-specimen amygdaloid complex total (both hemispheres), cm3 -> mm3
bg07 <- rd_cd("10.1002%2Fajpa.20684_TABLE1")
if (!is.null(bg07) && "amygdaloid_complex_total" %in% names(bg07))
  addspec(bg07$species, "Amygdala_Vol.mm3", numv(bg07$amygdaloid_complex_total) * 1000, "Barger2007_specimen")
# Sherwood 2004: per-specimen great-ape volumes, cm3 -> mm3 (species forward-filled, subspecies -> binomial)
s4 <- rd_cd("10.1002%2Fajp.20048_TABLEI")
if (!is.null(s4)) {
  sp4 <- str_squish(as.character(s4$Species)); sp4[sp4 %in% c("NA", "")] <- NA
  for (i in seq_along(sp4)) if (is.na(sp4[i]) && i > 1) sp4[i] <- sp4[i - 1]
  sp4 <- word(sp4, 1, 2)
  for (cw in list(c("Whole Brain", "Total_brain_net_volume_Vol.mm3"), c("Neocortex", "Neocortex_Vol.mm3"),
                  c("Hippocampus", "Hippocampus_Vol.mm3"), c("Striatum", "Striatum_Vol.mm3"),
                  c("Thalamus", "Thalamus_Vol.mm3"), c("Cerebellum", "Cerebellum_Vol.mm3")))
    if (cw[1] %in% names(s4)) addspec(sp4, cw[2], numv(s4[[cw[1]]]) * 1000, "Sherwood2004_specimen")
}
# Bush & Allman 2004 (V1 table): composite Neocortex (GM+WM) = grey + white, cm3 -> mm3 (species-level)
bu <- rd_cd("10.1002%2Far.a.20114_TABLE1")
if (!is.null(bu) && all(c("neocortex_grey_cm3", "neocortex_white_cm3") %in% names(bu)))
  addspec(bu$species, "Neocortex_Vol.mm3",
          (numv(bu$neocortex_grey_cm3) + numv(bu$neocortex_white_cm3)) * 1000, "Bush_Allman_2004_neocortex_GMWM")
unf_spec <- bind_rows(spec)
unf <- bind_rows(unf, unf_spec)
message("Per-specimen supplement: +", nrow(unf_spec), " candidate rows from ",
        length(unique(unf_spec$Source)), " specimen/composite sources.")

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
  "Agranular Insula"      = "Agranular_insular_cortex_Vol.mm3",
  "Insula (GM)"           = "Insula_Vol.mm3"
)
# regions with no clean single counterpart in our merge -> left out of the crosswalk:
#   Striatum (incl. NAcc) (a striatum+NAcc composite not carried by any source table we hold; its 44
#   DeCasien cells match nothing here). Agranular Insula IS now crosswalked -- the per-specimen
#   Bauernfeind reconstruction below (agranular_L + agranular_R, or 2x left) reproduces DeCasien's
#   agranular values (36/38 cells, mostly exact), so the old "we carry _left/_right separately"
#   exclusion no longer applies.
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

## ---- Tier 3: species-MEAN stand-in for unpublished individuals -------------------------------
## Some sources DeCasien compiled per-specimen never published the individual brains (Barks 2014,
## Gorilla): we hold only the species mean, so the per-brain rows can't match one-to-one. But
## DeCasien's GROUP MEAN over its individual rows for a (taxon, region, reference) equals our held
## species mean within tol -- e.g. Gorilla beringei: mean of the 14 individuals = 2969.5 vs our
## Barks hippocampus 3000 (1.0%). For rows still decasien_only, we compute that group mean and match
## it (same genus + same structure). Recovered rows get status "species_mean_match": the average
## stands in for the missing individuals. Grouped by ref_ids so individuals from ONE reference are
## averaged together (never mixing, say, Stephan and Barks rows for the same taxon/region).
gm <- cmp %>% filter(status == "decasien_only", !is.na(our_term)) %>%
  group_by(taxon, genus, our_term, ref_ids) %>%
  summarise(dec_group_mean = mean(dec_value, na.rm = TRUE), n_ind = n(), .groups = "drop")
if (nrow(gm)) {
  gmm <- pmap_dfr(list(g = gm$genus, val = gm$dec_group_mean, term = gm$our_term), match_row)
  upg <- bind_cols(gm, gmm) %>%
    filter(!is.na(matched_variable) & matched_variable == our_term) %>%
    transmute(taxon, our_term, ref_ids, m_src = matched_source, m_var = matched_variable,
              m_sp = matched_sp, m_val = matched_value, dec_group_mean)
  cmp <- cmp %>% left_join(upg, by = c("taxon", "our_term", "ref_ids")) %>%
    mutate(is_mean = status == "decasien_only" & !is.na(m_src),
           matched_source   = ifelse(is_mean, paste0(m_src, "_speciesmean"), matched_source),
           matched_variable = ifelse(is_mean, m_var, matched_variable),
           matched_sp       = ifelse(is_mean, m_sp,  matched_sp),
           matched_value    = ifelse(is_mean, m_val, matched_value),
           pct_diff         = ifelse(is_mean, round(abs(m_val - dec_group_mean) / abs(m_val) * 100, 3), pct_diff),
           status           = ifelse(is_mean, "species_mean_match", status)) %>%
    select(-m_src, -m_var, -m_sp, -m_val, -dec_group_mean, -is_mean)
}
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
  sprintf("- species_mean_match (individuals unpublished, e.g. Barks; DeCasien's group mean == our species mean within tol): **%d**", get("species_mean_match")),
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
        " species_mean_match=", get("species_mean_match"),
        " other=", get("value_match_other_structure"), " decasien_only=", get("decasien_only"),
        " | taxonomy proposals=", nrow(prop))
