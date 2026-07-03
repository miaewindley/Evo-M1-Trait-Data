# Merging histologically-derived brain-structure volumes

Pipeline for compiling the comparative brain **volume** dataset — the counterpart of
`../__merging_cellcounts/`, built by copying that folder's structure. **One data type
only**: volumes from sectioned, stained, shrinkage-corrected brains. (Cell-count /
optical-fractionator data live in `../__merging_cellcounts/`.)

## Teams and the two-tier resolution rule

By analogy to the cell-count merge (Herculano-Houzel updating her own collection →
take most recent; Kverkova a different lab → average): a duplicate
(species × structure × measure) is resolved by **which team measured which specimens**.

**Tier 1 — the Stephan / Düsseldorf collection** (one evolving dataset by a coauthor
group on the same C&O Vogt specimens). Duplicates resolved by **most recent
publication date** (the later paper supersedes the earlier), *unless flagged*:

> Stephan 1981 / 1982 / 1984 / 1987, Frahm 1982 / 1984 / 1994 / 1997 / 1998,
> Baron 1983 / 1987 / 1988 / 1990, Matano 1985a / 1985b, Zilles & Rehkämper 1988.

Worked example: the amygdala is taken from **Stephan 1987** (its re-measurement)
over Stephan 1981 — e.g. *Alouatta seniculus* 426 (1987) not 413 (1981).

**Tier 2 — independent series** (different specimens / labs / segmentation, same data
type). Each is its **own team**; across teams the values are **averaged** with the
Tier-1 result:

> de Sousa 2010 + 2013 (one "deSousa" team), MacLeod 2003, Bauernfeind 2013, Bush & Allman 2003,
> Smaers 2011 (frontal), **Barger 2007** (amygdala; team `Zilles` = the Semendeferi/Zilles collection,
> averaged with the Stephan-collection amygdala).

## Hemispheres: the merge unit is the COMBINED (left + right) volume

Brain-structure volumes are merged as **whole-structure, both-hemisphere** values:
- where a paper measured **one hemisphere and doubled it** (assuming symmetry) or already reports a
  both-sides total (Stephan/Frahm/Baron/Zilles/Matano; MacLeod `hemisphere` = both lateral hemispheres
  summed; Barger `amygdaloid_complex_total` = L + R), the reported both-sides volume is used directly;
- where a paper reports **left and right separately** (Smaers 2011 `frontal_*_total` = left + right),
  the merge uses **left + right added**.

### One-side-only structures (suffix-only laterality convention)

Some sources report a structure from **one side only**. Such a value must never be silently compared,
superseded, or averaged against a both-sides volume — that is exactly what produced the Baron 1988 vs
Stephan 1981 vestibular ≈ 2× mismatch. We mark these in the **standardized term itself** with a laterality
suffix — `_unilateral` (side unspecified), `_left`, or `_right` — so a one-side value becomes a *distinct
variable* that cannot collide with a both-sides column. Current one-side columns are registered in
`laterality_known.csv` and enforced by the **laterality guard** in `volumes_compiled.R` (it warns if the
registry and the term map disagree):

| Source | Columns | Side | Suffix |
|---|---|---|---|
| Stephan 1981 | Complexus vestibularis + 4 vestibular nuclei (codes 35–39) | one side (per Baron 1988) | `_unilateral` |
| Bauernfeind 2013 | insula: granular, dysgranular, agranular, FI, total | **left** = Table 1 (`_left`); **right** = Table 2 (`_right`) | `_left` / `_right` |

Left (Table 1) and right (Table 2) are combined into whole-insula both-hemisphere volumes in
`volumes_compiled.R` (step 7): both sides → left + right; left-only species → 2× left, flagged.

Numeric values are **not** doubled; a both-sides estimate, if needed, is derived downstream as `2 ×` and
flagged (`estimated_bilateral_from_unilateral = TRUE`), never overwriting the original. Individual-hemisphere
volumes from both-sides papers (e.g. Smaers `frontal_white_left_cm3`/`_right_cm3`, Barger `amygdaloid_complex_L`/`amygdaloid_complex_R`) are
preserved in each paper's source CSV/TSV but not carried into the merged table.

**Adding a one-side column:** register it in `laterality_known.csv` and give its standardized term the
matching suffix; the guard warns at compile time if the two disagree.

Worked examples: *Microcebus* neocortical grey = mean(Frahm 1982, Bush 2003);
*Pan troglodytes* LGN = mean(Stephan-collection 356, deSousa-team mean 297) = 327.

**Exception — body & brain weight** (specimen attributes, often re-used, not refined):
the **Stephan 1981 reference** is kept (newer values only fill gaps); these are **not**
cross-team averaged.

**Flags** (`volumes_flags.csv`): where a superseding value deviates > 50 % from the
value it replaces, it is flagged for review (the most-recent value is still taken).
This auto-surfaces things like Baron 1988's "both sides" vestibular volumes (≈ 2× the
Stephan 1981 one-side figures) and is where your manual exceptions live (e.g. you kept
Frahm 1984 over de Sousa for *Avahi laniger* area striata).

*Status of the amygdala-complex flags (Stephan 1987 vs 1981).* These are **not** a one-side/both-side
issue: 1987 `amygdala_total` is defined to equal the 1981 amygdala and Barger AC, and 74/76 species agree
within ±25 % (only Homo and Crocidura deviate). They resolve as:
- **Callithrix jacchus NTO** (0 vs 0.195): the 1987 `0` is a "not determinable with certainty" sentinel
  (per the 1987 data dictionary), now mapped to `NA` in `volumes_compiled.R`, so the real 1981 value 0.195
  is kept and the flag clears.
- **Homo sapiens amygdala** (1981 3015 < Barger 3805 < 1987 5286.6): a genuine remeasurement disagreement,
  resolved by **cross-team averaging** once Barger (team `Zilles`) is added → 4545.8, matching the curated
  `../Stephan_etal_1987/comparison/Stephan1987_AMY_vs_Barger2007_AC.csv` merged mean. The Tier-1 flag still
  fires (informational); the final merged value is the average.
- **Crocidura flavescens** (≈ 1.8–2.0×): a **taxonomy lump** — the 1981 row is "Crocidura *occidentalis*",
  keyed to accepted "Crocidura *flavescens*" to meet the 1987 row. **Verify these are the same
  specimens/species** before trusting the gap; this is the only amygdala flag still genuinely open.

## Steps

1. `standardized_term.R` → `standardized_term_volumes.csv` (stacks the per-reference
   `standardized_term_by_reference/<Reference>_standardized_terms.csv` maps:
   `Species`, `Body_Mass.g`, `Brain_Mass.mg`, one `<CanonicalStructure>_Vol.mm3` each).
2. `volumes_compiled.R` → reads each paper's DOI/PMID-coded TSV, applies the terms, resolves
   species (step 4, below), runs the two-tier resolution above. Paper-specific reshapes (step 3):
   Zilles 1988 (structure-rows → one *Pongo* row), Bauernfeind 2013 & MacLeod 2003 & **Barger 2007**
   (per-individual → species means; Bush & MacLeod & Barger cm³ → mm³; Bauernfeind brain mg → g);
   **Stephan 1987** NTO `0` → `NA` (not-determinable sentinel).
   Outputs: `volumes_long.csv`, `volumes_wide.csv`, `volumes_flags.csv`; audit
   `volumes_unfiltered.csv`; species review table `volumes_source_species_ids.csv`; source
   inventory `volumes_species_sources.csv`. Needs `tidyverse`, `readxl`, **`taxizedb`**.

### Species resolution (step 4 — mirrors `../__merging_cellcounts` §4, with extras)

No per-paper "tokens" any more. The species **column** is found from the term map (the
`Original_Term` whose `Standardized_Term == "Species"`), and species **names** are resolved in a
single layered pass over the long table:

- **NCBI backbone** — `taxizedb::name2taxid`/`taxid2name` give the preferred scientific name for
  each raw name (source-independent), exactly as the cell-count merge does.
- **Curated overrides win** — the project's deliberate taxonomy decisions (genus-level lumping like
  `Gorilla sp.`/`Pongo sp.`, subspecies→binomial, synonyms like *Lophocebus albigena*) override
  NCBI. They live in `_keys/volumes_species_overrides.csv` (`Reference, variant_name,
  accepted_name, note`) and are applied **source-aware** — keyed by `Reference` (= item name) **and**
  the raw variant — so the same label can resolve differently in different papers. This file was
  generated from the per-team `_keys/*/species_key.csv` (non-identity rows only), re-keyed from the
  old cryptic `source_publication` tokens to item names; edit it directly to add/adjust a decision.
- **Order**: curated → else NCBI preferred → else the raw name (flagged `unresolved_raw`).
- **Review table** `volumes_source_species_ids.csv` records, per (Source, raw name): NCBI name,
  curated name, final name, and flags (`flag_curated_overrides_ncbi`, `flag_unresolved`) for sign-off.
- Variants that now collapse to one accepted name are **aggregated/averaged** by the two-tier rules
  in steps 5–6.
3. **Hemisphere reconciliation** (step 7 of `volumes_compiled.R`; see `volumes_wide.NOTE.md`).
   Add whole-structure both-hemisphere variables (no laterality suffix): sum left + right where
   both sides exist (Bauernfeind insula = Table 1 + Table 2); otherwise estimate as 2× the one
   measured side and flag it (`estimated_bilateral_from_unilateral`), preferring a genuine
   both-sides value over an estimate. One-side columns are kept for traceability.

## Current state

**30 tables merged → 281 species × volume variables** — the canonical collection only.
Tier 1 (17, Stephan_collection): Stephan 1970/1981/1982/1984/1987,
Frahm 1982/1984/1994/1997/1998, Baron 1983/1987/1988/1990, Matano 1985a/1985b, Zilles 1988.
Tier 2 (independent series): de Sousa 2010, de Sousa 2013, MacLeod 2003, Bauernfeind 2013
(insula = **left**, `_left`), Bush & Allman 2003, Bush & Allman 2004b, Smaers 2011 (combined
L+R frontal grey/white), Barger 2007 (amygdala, team `Zilles`), Ashwell 2020, Semendeferi
1998/2001, Sherwood 2005.

**DeCasien comparison is separate (revised 2026-06-28).** The 2026-06-24 expansion that folded the
DeCasien sources (Sherwood 2004 `_TABLEI`, Barks 2014, Rilling & Insel 1998/1999, Stimpson 2015,
and the `*_viaDeCasien` tables) *into* this merge was reverted: cross-team averaging shifted
great-ape values away from DeCasien's single-source figures (44 regressions; see
`_EXPANSION_FINDINGS.md`). Those papers are no longer compiled here. The merge-vs-DeCasien
comparison lives in its own scripts. Two ways to compare:
(1) **value-match** (recommended; needs only the core merge):
`../DeCasien_Higham_2019/DeCasien_Higham_2019_SupplementaryData1-BrainRegion.R` value-matches
DeCasien's published MOESM3 numbers against this core merge's `volumes_unfiltered.csv` /
`volumes_long.csv`. It now takes an optional `merge_suffix` (default `""` = core).
(2) **expanded-merge build** (`volumes_compiled_DeCasien.R`): a dedicated sibling that mirrors this
engine but ADDS the DeCasien-overlapping papers, writes `volumes_*_EXPANDED.csv` (never the canonical
`volumes_*.csv`), then `source()`s script (1) with `merge_suffix <- "_EXPANDED"` to produce
`DeCasien_vs_merge_comparison_EXPANDED.csv` + `_EXPANDED` findings. Use it only for the comparison;
the canonical dataset stays core-only here.

Species harmonization: `MacLeod_etal_2003_` and `Smaers_etal_2011_*` now carry species_key tokens
`MacLeod2003` / `Smaers2011` (added to `_keys/Stephan/species_key.csv`), which lump great apes to the
dataset convention (`Gorilla sp.`, `Pongo sp.`) and fix Smaers synonyms — replacing the old NA
("species as-is") that had left `Gorilla gorilla` etc. unmerged. Bugfix 2026-06-28: the
generic wide→long step now excludes the species column from `keep`, so a paper whose species column
is literally named `Species` (Sherwood 2004) no longer has its names coerced to NA doubles — that
was the `bind_rows` "`..N$Species <double>`" crash.

**Note:** `Sherwood_etal_2004_I/` is a *different* paper (M1 GLI cytoarchitecture, not volumes)
— not the ref-64 source. The ref-64 great-ape volumes are `Sherwood_etal_2004_TABLEI`. Baron
1987 olfactory and Baron 1988 vestibular abbreviations are mapped (BOL→Bulbus_olfactorius,
VC→Complexus_vestibularis, VI→…descendens, etc.) — sanity-check those against the papers.

## Cross-publication comparisons (`crosspub_*`)

Some later papers **re-use earlier data under new labels** (different species names and/or anatomical
terms). To detect this — *if the values are identical, it is the same data* — `crosspub_value_match.R`
matches one publication's volumes against the merged dataset and the per-source TSVs **by value**
(species-agnostic, within tolerance), writing `crosspub_<paper>_value_match.csv`. First target:
**Smaers 2017** Table S1 (its cortical-area volumes vs the Stephan-collection / de Sousa / Smaers 2011
sources), using `../Smaers_etal_2017/primary_source_checks/species_name_changes_2011_to_2017.csv`
(which already records the 2011→2017 relabelings, e.g. *Cercocebus*→*Lophocebus albigena*, "values identical").

## Adding a paper
1. Create `standardized_term_by_reference/<Reference>_standardized_terms.csv`.
2. Ensure its TSV is in `__Public/comparative-data/`; add it to `item_name` with its
   `team` (default `Stephan_collection`) and `token` (species_key) in `volumes_compiled.R`.
3. Re-run `standardized_term.R`, then `volumes_compiled.R`.
