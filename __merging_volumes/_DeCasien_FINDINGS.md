# Volume merge — health check + DeCasien (2026-06-24)

> **Update — run 2 (real primaries + reference audit).** You added real primary tables, so the
> four DeCasien sources are now integrated as a **hybrid**: real primaries provide brain
> volume/mass + the structures they measure; DeCasien-extracted (`*_viaDeCasien`) tables fill
> only the structures the primaries lack (no double-counting).
> - **Sherwood 2004** (`_TABLEI`, DOI 10.1002/ajp.20048): full primary (BV, cerebellum, neocortex,
>   thalamus, striatum, hippocampus).
> - **Barks 2014** (`_TABLE1`, ajpa.22646): brain volume from primary; cerebellum/neocortex/
>   striatum/hippocampus/amygdala/insula from DeCasien.
> - **Rilling & Insel 1998** (`_Table1`, 000006575): brain volume + cerebellum + body mass from
>   primary; **neocortex re-attributed to Rilling & Insel 1999 (ref 63)** = `Rilling_Insel_1999_viaDeCasien`.
> - **Stimpson 2015** (`_TableS1`, nsv128): **brain mass** (→`Brain_Mass.mg`) from primary;
>   DeCasien BV + amygdala kept via `_viaDeCasien`. (TableS2 amygdala subnuclei are one-side —
>   left out of the auto-merge pending laterality handling; see note below.)
>
> **Reference audit** (you flagged possibly-wrong refs — see `DeCasien_Higham_2019/DeCasien_reference_audit.md`
> + `DeCasien_reference_audit.csv`): DeCasien's compound refs are two papers each. Confirmed by
> exact value-match (Rilling cerebellum 9/9 = 0.0%; Sherwood/Barks brain vol match). The one real
> fix: **62-63 neocortex = Rilling & Insel _1999_**, not 1998 — corrected.
>
> **Pipeline robustness:** your ongoing re-encoding of TSV filenames kept breaking lookups
> (Stephan 1970 `ISBN%3A 0390…` stray space; Semendeferi `<`→`%3C`; MacLeod `_`→`_Table1`).
> `read_item()` now matches item names **case-insensitively** and **strips stray spaces** from
> encodings (keeping their case), so registry drift no longer breaks the build.
>
> **Current totals: 37 source tables → 282 species × 118 variables.** DeCasien coverage:
> unmatched cells 358→162 (−55%). Stimpson primary **brain mass** follows the merge's mass rule
> (Stephan-reference/gap-fill, not cross-team averaged).
>
> Below is the original run-1 writeup (still accurate except counts now 37 tables).

---


Two requests: (1) confirm the volume merge is up and working; (2) limit it to include
all DeCasien & Higham 2019 data (volumes **and** brain-weight), for a full merge-vs-DeCasien
comparison.

## 1. Is the merge "up and working"? — Yes, after two fixes

**Data is intact and fully reproducible.** A clean re-implementation of `volumes_compiled.R`
reproduced the committed outputs **exactly**: 281 species × 118 variables, 7,152 long-format
cells, **0 value mismatches**, and an identical 108 flags (7 deviation + 101 bilateral
estimates). The dataset itself was never corrupted.

**Two things were broken in the working tree (now fixed):**

1. **`volumes_compiled.R` had been deleted** (uncommitted). Restored from git HEAD. Note the
   restored script already lists **all 30 source tables** from the project instructions — the
   README's "23 tables / 152 species" was simply stale (actual: 30 tables / 281 species).
2. **File-resolution drift from an in-progress rename** to DOI/ISBN-encoded TSV filenames.
   Three papers no longer resolved because the `papers` item names didn't match the
   `__ReadMe.xlsx` rows (which point at the deleted `NA.tsv`):
   - `MacLeod_etal_2003_` (xlsx row is `MacLeod_etal_2003_Table1`; the data file on disk is
     `…00028-9_.tsv`, not `…_Table1.tsv`)
   - `Semendeferi_etal_1998_Table2` / `_2001_Table2` (xlsx rows use `…_TABLE2`, a case mismatch)

   Fixed by adding correct `enc_override` entries and a guard in `read_item()` that falls back
   to the override when the registry-resolved file is missing. Stephan 1970 resolves fine via
   its new ISBN encoding (`ISBN%3A0390672505_Tables1-6`); its stale override was updated too.

## 2. DeCasien data — done

DeCasien's brain-region sheet cites four sources the merge lacked.

**Sherwood 2004 (ref 64) is a real primary source** — `Sherwood_etal_2004/Sherwood_etal_2004_TABLEI`
(DOI 10.1002/ajp.20048, "Brain structure variation in great apes"), per-specimen volumes in cm³,
reshaped to species means (forward-fill species, subspecies→binomial, ×1000 to mm³). It
reproduces DeCasien's ref-64 figures **exactly** for *Pan troglodytes* and *Pongo pygmaeus*.
(Note: the local `Sherwood_etal_2004_I/` folder is a *different* paper — M1 GLI cytoarchitecture,
not volumes — and is not used here.)

The other three lack a clean local volume table, so — following the repo's existing
`Barks_etal_2014_viaDeCasien.csv` pattern — they were extracted from DeCasien MOESM3
"Brain Region Data (mm3)" (values already mm³, taxa harmonized to accepted binomials = first two
tokens of DeCasien's name). Each new source is its own Tier-2 team:

| Source (new item) | DeCasien ref | Team | Species | Structures contributed |
|---|---|---|---|---|
| `Rilling_Insel_1998_viaDeCasien` | 62-63 | RillingInsel | 10 | BV, Cerebellum, Neocortex (GM+WM), Neocortex (GM) |
| `Sherwood_etal_2004_TABLEI` (primary) | 64 | Sherwood | 4 | Whole brain (BV), Cerebellum, **Neocortex (total)**, Thalamus, Striatum, Hippocampus |
| `Barks_etal_2014_viaDeCasien` | 65 | Barks | 2 | BV, Cerebellum, Neocortex (GM+WM/GM), Striatum, Hippocampus, Amygdala, Insula (GM) |
| `Stimpson_etal_2015_viaDeCasien` | 58 | Stimpson | 2 | BV, Amygdala |

Sherwood 2004's "Neocortex" column is mapped to total `Neocortex_Vol.mm3` (not GM), the literal
reading of the primary table — this differs slightly from DeCasien, which filed ref-64 neocortex
under "Neocortex (GM)".

**Brain-weight (`BV`)** is mapped to `Total_brain_net_volume_Vol.mm3` (DeCasien's BV is a
brain *volume* in mm³, not a mass).

### What changed in the merge (34 tables now)
- **281 → 282 species** (Gorilla beringei is new), 118 variables unchanged.
- **+25 new data cells**, 0 lost.
- **36 existing values changed**, all in the great-ape / monkey species and structures the new
  sources cover (cross-team averaging) — no Stephan / prosimian / insectivore data was touched.

### Region → canonical-term crosswalk used
BV→Total_brain_net_volume · Cerebellum→Cerebellum · Neocortex (GM+WM)→Neocortex ·
Neocortex (GM)→Neocortex_grey_matter · Thalamus→Thalamus · Striatum→Striatum ·
Hippocampus→Hippocampus · Amygdala→Amygdala · Insula (GM)→Insula.

## 3. Merge vs DeCasien comparison (2,152 crosswalked cells, same-species, 2% tol)

| status | original merge | DeCasien merge |
|---|---|---|
| match (exact, ≤2%) | 897 | 925 |
| value_diff (covered but >2% off) | 897 | 1065 |
| decasien_only (not covered) | **358** | **162** |

**Unmatched DeCasien cells fell 358 → 162 (−55%).** Transition detail:
- 25 `decasien_only → match`, 47 `value_diff → match` (improvements)
- 171 `decasien_only → value_diff`: now covered, but the merged value differs from DeCasien
- **44 `match → value_diff` (regressions)** ⚠️

### ⚠️ Decision for review: cross-team averaging vs DeCasien reproduction
The 173 new value_diffs and the 44 regressions have one cause: the merge **cross-averages
independent teams** for a species×structure, whereas DeCasien picked a **single source per
cell**. So adding Barks/Sherwood/Rilling to, e.g., *Pan troglodytes* cerebellum changes our
averaged value away from the single DeCasien figure it used to equal.
This is expected behaviour, not a bug. If the goal is to **reproduce** DeCasien, consider
treating `BV`/whole-brain volume as gap-fill-only (like Body/Brain mass) rather than averaged.
The current build averages it. Say the word and I'll switch BV to gap-fill.

## Files
- **Canonical outputs now hold the DeCasien, real-Sherwood data** (34 tables, 282 species):
  `volumes_long.csv`, `volumes_wide.csv`, `volumes_flags.csv`, `volumes_source_species_ids.csv`.
  Identical `*_DeCasien.csv` copies are kept for reference. (A prior R run had produced the merge
  using the placeholder via DeCasien Sherwood; these files now reflect the real primary.)
- New inputs: `__Public/comparative-data/10.1002%2Fajp.20048_TABLEI.tsv` (Sherwood 2004 primary)
  and `*_viaDeCasien.tsv` (Rilling, Barks, Stimpson); matching maps in
  `standardized_term_by_reference/`.
- `DeCasien_vs_merge_comparison_DeCasien.csv` — per-cell baseline-vs-DeCasien status.
- `volumes_compiled.R` updated: enc_override fixes; Sherwood 2004 primary (`Sherwood_etal_2004_TABLEI`)
  with a forward-fill/binomial/cm³→mm³ reshape; 3 viaDeCasien tribble rows. `standardized_term.R`
  auto-stacks the new term maps; `standardized_term_volumes.csv` rebuilt (34 references).

## To regenerate canonically in R
`Rscript standardized_term.R` then `Rscript volumes_compiled.R` (needs `tidyverse`, `readxl`).
The Python reproduction (`repro_volumes.py` / `expand_volumes.py`) is a validation mirror.
