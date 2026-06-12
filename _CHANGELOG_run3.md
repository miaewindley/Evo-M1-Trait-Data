# Evo-M1-Trait-Data - run 3 (the 4 follow-ups, folded into the merge) - summary for maintainer

Builds on the previous run's baseline (**277 species x 117 variables, 29 tables, 108 flags**;
documented in `upload_Evo-M1-Trait-Data/_CHANGELOG_M1_volume_tables.md`). All R run on R 4.5.2 via an
external path-rewriting runner, so committed scripts keep their OneDrive `setwd()` and the repo diff
stays clean. **No commit/push.** The 27 changed/new files below are staged in
`upload_Evo-M1-Trait-Data_run3/` (same relative paths) plus this changelog.

This run executes all four requested follow-ups (and the 5th, the Semendeferi registry rows) and
folds them into the compiled datasets - nothing is left to wire up by hand.

## Result
Volume merge: **281 species x 118 variables, 30 tables, 108 flags**, laterality guard OK (20 one-side
columns). Vs baseline: **+4 species, +1 variable, +1 table, flags unchanged.**
- +1 table  = Stephan, Bauchot & Andy 1970 (`Stephan_etal_1970_Tables1-6`).
- +1 variable = `Palaeocortex_plus_amygdala_Vol.mm3` (kept distinct from `Palaeocortex_Vol.mm3`; 63 species).
- +4 species = Crocidura occidentalis, Hapalemur simus, Cebus sp., Rhynchocyon stuhlmanni (the Stephan
  1970 species with no existing merge counterpart; the other 59 consolidated onto existing rows).
- No new flags: as the oldest Stephan table, 1970 is superseded by 1981+ in Tier-1, so no >50% deviations.

---

## Part 1 - Stephan 1970 activated into the volume merge
DRAFT trusted as-is (per request). Followed the folder's `Stephan_etal_1970.ReadMe.md` activation steps:
- Promoted DRAFT snapshots to non-DRAFT (`..._Tables1-3_snapshot.csv`, `..._Tables4-6_snapshot.csv`);
  `Stephan_etal_1970.R` now reads them and regenerates `Stephan_etal_1970_Tables1-6.csv/.tsv` (63 species).
  Internal check still holds: 7 telencephalon components sum to the Telencephalon total to **max 0.35%,
  median 0.006%, 0 species >1%**.
- Copied the READY term map to
  `__merging_volumes/standardized_term_by_reference/Stephan_etal_1970_Tables1-6_standardized_terms.csv`
  and the clean TSV to `__Public/comparative-data/Stephan_etal_1970_Tables1-6.tsv`.
- `volumes_compiled.R`: added the `papers` row
  `"Stephan_etal_1970_Tables1-6","Stephan_collection",1970,"Stephan1970","species"` and an
  `enc_override` entry.
- `_keys/Stephan/species_key.csv`: added a **15-row `Stephan1970` token block** reconciling 1970 names to
  existing accepted names (e.g. Aotes trivirgatus->Aotus trivirgatus, Lagothrix logotricha->Lagothrix
  lagothricha, Cercocebus albigena->Lophocebus albigena, Lemur fulvus->Eulemur fulvus, Galago
  crassicaudatus->Otolemur crassicaudatus, Colobus badius->Piliocolobus badius, ...). Subspecies-rank
  and unmatched names (Crocidura occidentalis, Hapalemur simus, Cebus sp., Rhynchocyon stuhlmanni) were
  left as their own rows rather than force-merged. (Note: `Gorilla gorilla` already exists as a precise
  merge row, so 1970's `Gorilla gorilla` joins it - it was NOT remapped to the vaguer `Gorilla sp.`)

## Part 2 - DeCasien taxonomy proposals applied
- Added the 6 proposed rows from `DeCasien_taxonomy_proposed_changes.csv` to `species_key.csv` under a
  comparison-only **`DeCasien` token** (DeCasien is not in `papers`).
- Taught `DeCasien_Higham_2019_SupplementaryData1-BrainRegion.R` to apply that `DeCasien` token to the
  DeCasien species name before the species-agreement test (previously the script never read species_key,
  so adopting the proposals would have had no observable effect). Re-ran it against the regenerated merge.
- Match counts (was 923 exact / 270 taxonomy-variant): now **1104 exact / 91 taxonomy-variant / 337
  value-match-other / 620 DeCasien-only**. The jump comes from (a) the merge now carrying the Stephan
  1970 binomials DeCasien uses, and (b) the 6 adopted reconciliations.
- Proposals **6 -> 2 remaining** (both newly surfaced by the Stephan 1970 rows, left for human review,
  not auto-adopted): `Avahi occidentalis -> Avahi laniger` and a Tarsius striatum cell
  (`Tarsius sp. <-> Tarsius syrichta`).

## Part 3 - Volume pipeline re-run
`standardized_term.R` then `volumes_compiled.R` (via the runner) regenerated
`standardized_term_volumes.csv`, `volumes_unfiltered.csv`, `volumes_long.csv`, `volumes_wide.csv`,
`volumes_flags.csv`, `volumes_source_species_ids.csv`. Counts and laterality guard as in **Result** above.

## Part 4 - Energetics compiled merge (built)
New `__energetics_comparison/energetics_merged.R` implements the proposed schema from
`ENERGETICS_FINDINGS.md`, mirroring `volumes_long`:
- Reads `energetics_long.csv`; standardizes units (CMRgl/CMRO2 = umol/100g/min; CBF = mL/100g/min).
- Region crosswalk harmonizes Heiss/Kaufman synonyms to canonical labels and links to `*_Vol.mm3`
  terms where a clean single counterpart exists (`Volume_term` column).
- Two-tier resolution: Heiss and Kaufman are independent Tier-2 teams, averaged across teams; Kaufman
  values are the weighted means (no unweighted rows present).
- Outputs: `energetics_merged_long.csv` (162 cells, 12 species), `energetics_merged_wide.csv` (12 rows x
  54 region-measure columns, one measure per column -> no unit collisions), and
  `energetics_merged.ReadMe.md`.
- Cross-check preserved: human cortical CMRgl Heiss 33.5 vs Kaufman 36.78 -> **averaged 35.14** (n_teams=2).
- **Karbowski 2007 stays excluded** (garbled OCR; never parsed into `energetics_long.csv`) - noted, not merged.

## Part 5a - Barbeito 2019 units verified (internal consistency) and applied
Internal-consistency check `cell_density x absolute_volume` vs `cell_number` (per group x region x
cell_type, group-mean volumes; Rest = Total - the four named regions): the ratio is consistent **across
cell types within each region** (e.g. Cerebellum/C: Neurons 1254, Non-neurons 1218, Total 1251) and
centres on **~10^3** (median 868, mean 944, n=45). Confirmed scaling (isotropic-fractionator convention,
volume mm3 ~ mg):
- **cell_density = published value x 10^3 cells/mg**;  **cell_number = published value x 10^6 cells**.
Applied to `BarbeitoAndres_etal_2019_tidy.csv` (`units` now `10^3 cells/mg` / `10^6 cells`) and
`..._definitions.csv`; evidence recorded in `..._ReadMe.md`. (Verification is by internal arithmetic;
no source-PDF text was needed.) Remaining caveat: the cell tables carry no specimen ids (`specimen = NA`),
so per-animal pairing to the volume table is not possible.

## Part 5b - Semendeferi registry rows added; enc_override removed
- Added two table-level rows to `__ReadMe.xlsx` Sheet1 (`Semendeferi_etal_1998_Table2`,
  `Semendeferi_etal_2001_Table2`; `Item name` = `Item encoded` = the table item, pointing at the existing
  `..._Table2.tsv`), copied from each paper's existing registry row (correct DOI/year/author), via
  `openxlsx::loadWorkbook`/`saveWorkbook`.
- Verified after saving: the original **120 rows are value-identical** (one benign exception - openxlsx
  normalized an embedded newline character inside one free-text title cell, row 49; text unchanged), and
  **all 1095 Sheet1 formulas are preserved** (identical `<f>` count, backup vs saved). No formula column
  was corrupted, so the safety rollback was not needed.
- Removed the two `Semendeferi_*_Table2` `enc_override` entries from `volumes_compiled.R`; re-ran the
  merge - all outputs **byte-identical** (MD5) to the pre-removal run. Registry is now self-sufficient
  for Semendeferi. (`Bauernfeind_etal_2013_Table2` and the new `Stephan_etal_1970_Tables1-6` keep their
  `enc_override` fallback by design.)

## Still blocked (absent from repo & Downloads)
Stimpson 2015, Rilling & Insel 1998, Barks 2014/2015 - their sources are not present, so they cannot be
added. Recorded here as blocked, not as action items.

---

## WHAT TO UPLOAD
Everything in `~/Desktop/upload_Evo-M1-Trait-Data_run3/` (27 repo files, original folder structure, +
this changelog). Zip and upload as-is. These are run-3 deltas only; run-2 files are already in
`upload_Evo-M1-Trait-Data/`.

### Modified (19) - the real review targets
- `__merging_volumes/volumes_compiled.R` (Stephan 1970 papers row + enc_override add, then Semendeferi
  enc_override removed)
- regenerated merge outputs: `standardized_term_volumes.csv`, `volumes_long.csv`, `volumes_wide.csv`,
  `volumes_unfiltered.csv`, `volumes_flags.csv`, `volumes_source_species_ids.csv`
- `_keys/Stephan/species_key.csv` (Stephan1970 15-row block + DeCasien 6-row block)
- `DeCasien_Higham_2019/DeCasien_Higham_2019_SupplementaryData1-BrainRegion.R` (applies the DeCasien
  token) + regenerated `DeCasien_vs_merge_comparison.csv`, `DeCasien_taxonomy_proposed_changes.csv`,
  `DeCasien_Higham_2019_FINDINGS.md`
- `Stephan_etal_1970/Stephan_etal_1970.R` (reads non-DRAFT snapshots) + regenerated
  `Stephan_etal_1970_Tables1-6.csv/.tsv`
- `BarbeitoAndres_etal_2019/` `..._tidy.csv`, `..._definitions.csv`, `..._ReadMe.md` (units)
- `__ReadMe.xlsx` (2 Semendeferi rows)

### New (8)
- `Stephan_etal_1970/Stephan_etal_1970_Tables1-3_snapshot.csv`, `..._Tables4-6_snapshot.csv` (promoted)
- `__merging_volumes/standardized_term_by_reference/Stephan_etal_1970_Tables1-6_standardized_terms.csv`
- `__Public/comparative-data/Stephan_etal_1970_Tables1-6.tsv`
- `__energetics_comparison/energetics_merged.R`, `energetics_merged_long.csv`, `energetics_merged_wide.csv`,
  `energetics_merged.ReadMe.md`
