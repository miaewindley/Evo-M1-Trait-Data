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
  summed; Barger `AC_total` = L + R), the reported both-sides volume is used directly;
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
| Bauernfeind 2013 | insula: granular, dysgranular, agranular, FI, total | **left** (paper's Table 1; right is its Table 2, not snapshotted) | `_left` |

Numeric values are **not** doubled; a both-sides estimate, if needed, is derived downstream as `2 ×` and
flagged (`estimated_bilateral_from_unilateral = TRUE`), never overwriting the original. Individual-hemisphere
volumes from both-sides papers (e.g. Smaers `frontal_white_left_cm3`/`_right_cm3`, Barger `AC_L`/`AC_R`) are
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
2. `volumes_compiled.R` → reads each paper's DOI/PMID-coded TSV, applies the terms,
   harmonizes species (`_keys/Stephan/species_key.csv` token + variant → accepted), runs
   the two-tier resolution above. Paper-specific reshapes (step 3): Zilles 1988
   (structure-rows → one *Pongo* row), Bauernfeind 2013 & MacLeod 2003 & **Barger 2007** (per-individual →
   species means; Bush & MacLeod & Barger cm³ → mm³; Bauernfeind brain mg → g); **Stephan 1987**
   NTO `0` → `NA` (not-determinable sentinel).
   Outputs: `volumes_long.csv`, `volumes_wide.csv`, `volumes_flags.csv`; audit
   `volumes_unfiltered.csv`; inventory `volumes_source_species_ids.csv`.

## Current state

**23 tables merged → ~152 species × ~89 volume variables** (re-run to refresh exact counts; Bauernfeind's
5 insula variables are renamed `…_left`, Barger maps to the existing `Amygdala_Vol.mm3`, so counts are
~unchanged). Tier 1 (16): Stephan 1981/1982/1984/1987, Frahm 1982/1984/1994/1997/1998,
Baron 1983/1987/1988/1990, Matano 1985a/1985b, Zilles 1988. Tier 2 (7): de Sousa 2010, de Sousa 2013,
MacLeod 2003, Bauernfeind 2013 (insula = **left**, `_left`), Bush & Allman 2003,
**Smaers 2011** (combined L+R frontal grey/white), **Barger 2007** (amygdala, team `Zilles`).

**Not yet included:** Sherwood 2005 brainstem motor nuclei; Bush & Allman 2004a/b. Baron 1987
olfactory and Baron 1988 vestibular abbreviations are mapped (BOL→Bulbus_olfactorius,
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
