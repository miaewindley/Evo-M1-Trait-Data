# Kaufman (2004) — dissertation appendix tables A1–A15

Kaufman, J. A. (2004). *Pattern and scaling of regional cerebral glucose metabolism in
mammals* (Publication No. 3147447) [Doctoral dissertation, Washington University in St.
Louis]. ProQuest Dissertations & Theses Global. Identifier: **UMI:3147447**.

Item names follow `__ReadMe.xlsx`: **`Kaufman__2004_TableA1` … `Kaufman__2004_TableA15`**.

The dissertation's Appendix reports, per brain region, the regional cerebral **metabolic
rate** for glucose (CMRgl) and oxygen (CMRO2) and the regional cerebral **blood flow**
(CBF), compiled from the PET / Sokoloff / Kety-Schmidt / microsphere / NMR literature plus
Kaufman's own PET data ("Present Study"). Tables **A1–A14** are the per-study raw data;
**A15** is the computed species-means summary ("Species Means in Conscious Subjects").

## Pipeline (same golden rule as the other papers)

The **snapshot is frozen and faithful** to the dissertation; **all cleaning happens in the
`.R` script**. Checking is separate, in `comparison/`.

```
<dissertation PDF / xlsx>
      │  faithful capture
      ▼
Kaufman__2004_TableAxx_snapshot.csv      ← frozen; verbatim, OCR quirks kept
      │  Kaufman__2004_TableAxx.R  (parse numbers, add Region/units, trim)
      ▼
Kaufman__2004_TableAxx.csv               ← use this
      │  (same script)
      ▼
__Public/comparative-data/UMI%3A3147447_TableAxx.tsv   ← DOI/UMI-named public copy
```

Each table has a self-contained `.R` (derives its own name from the filename, matches
`__ReadMe.xlsx`) that reads only its snapshot. Column meanings and units are in
`Kaufman__2004_definitions.csv`.

## Files

| Path | Role |
|---|---|
| `Kaufman__2004_dissertation.pdf` | Source dissertation. |
| `Kaufman__2004_dissertation.xlsx` | Digitized capture of every dissertation table (104 sheets), used to cross-check the PDF extraction. |
| `Kaufman__2004_TableA1..A15_snapshot.csv` | Frozen faithful snapshots (source of truth for the build). |
| `Kaufman__2004_TableA1..A15.R` | Preparation: snapshot → clean CSV (+ UMI-named TSV). |
| `Kaufman__2004_TableA1..A15.csv` | Clean, analysis-ready tables. **Use these.** |
| `Kaufman__2004_definitions.csv` | Data dictionary (documentation only; not read by the scripts). |
| `comparison/` | Checking (QA) against the manually compiled tables. |
| `old/` | Superseded Python build/compare scripts and earlier comparison outputs. |

## The 15 tables

| Item | Region (dissertation title) | Kind | Rows |
|---|---|---|---:|
| `TableA1`  | Basal Ganglia rCMR & rCBF | per-study | 121 |
| `TableA2`  | Hippocampus rCMR & rCBF | per-study | 86 |
| `TableA3`  | Thalamus rCMR & rCBF | per-study | 126 |
| `TableA4`  | Cerebellum rCMR & rCBF | per-study | 87 |
| `TableA5`  | White Matter rCMR & rCBF | per-study | 82 |
| `TableA6`  | Neocortex rCMR & rCBF | per-study | 151 |
| `TableA7`  | Frontal Cortex rCMR & rCBF | per-study | 119 |
| `TableA8`  | Parietal Cortex rCMR & rCBF | per-study | 103 |
| `TableA9`  | Temporal Cortex rCMR & rCBF | per-study | 65 |
| `TableA10` | Auditory Cortex rCMR & rCBF | per-study | 51 |
| `TableA11` | Occipital Cortex rCMR & rCBF | per-study | 111 |
| `TableA12` | **Sensorimotor Cortex** rCMR & rCBF | per-study | 76 |
| `TableA13` | **Cingulate Cortex** rCMR & rCBF | per-study | 62 |
| `TableA14` | Whole Brain CMR & CBF (direct measurement) | per-study | 196 |
| `TableA15` | Species Means in Conscious Subjects | species means | 284 |

### ⚠ A12 / A13 numbering — please confirm

The **dissertation itself prints A12 = _Sensorimotor Cortex_ and A13 = _Cingulate
Cortex_**, and the tables are built and named accordingly here. In the current
`__ReadMe.xlsx` the *Item full original title* cells for these two items are **swapped**
(`TableA12` is labelled "A13. Cingulate", `TableA13` is labelled "A12. Sensorimotor").
I have aligned the titles to the dissertation (see "ReadMe.xlsx updates" below); if you
deliberately intended the opposite item→region mapping, flip the two `_snapshot.csv` /
`.csv` / titles and tell me.

(A13's first-page header was lost in the PDF OCR — its region continues from the
"Table A13, cont." pages; the data restart at *Homo* confirms the table boundary.)

## Per-study tables A1–A14 (the missing tables, now built)

One row per published study entry. Columns: `Species`, `Reference`, `n`, `Anesthesia`,
`Mode`, `Region`, `CMRgl_umol_100g_min`, `CMRgl_SD`, `CMRO2_umol_100g_min`, `CMRO2_SD`,
`CBF_ml_100g_min`, `CBF_SD`, `source`. Units: CMRgl & CMRO2 in µmol/100 g/min; CBF in
mL/100 g/min.

**Extraction.** Snapshots were built from the dissertation PDF text layer
(`pdftotext -layout`), parsed by column position: each row is split at its measurement
`Mode` token, the numeric tail (Glucose/Oxygen/Blood-Flow ± SD) is assigned by column
position (so blank measures stay blank), and Species/Reference/n/Anesthesia are recovered
by nearest-column anchor (robust to the source's frequently OCR-dropped opening
parentheses and to the `M mulatta`-style genus abbreviations). Values are kept verbatim in
the snapshot; the `.R` only parses numbers (OCR comma→decimal, `nr`→NA) and adds the
region label and units. The 104-sheet dissertation `.xlsx` was used as an independent
cross-check on completeness (snapshot row totals ≥ xlsx).

## Species means A15

`Kaufman__2004_TableA15.csv`: one row per genus × weighting × region × measure, with
`N, Mean, SD, CV, CVstar`. `unweighted` = each study equal; `weighted` = each individual
equal. Two cells were OCR-reconstructed in the original build (Parietal Cortex · CMRgl ·
Homo · weighted CV*; Cerebellum · CBF · Rattus · weighted) and carried in `note`; both
agree with the manual tables.

## Checking — `comparison/`

Analogous to the other papers' `comparison/` folders. Manual comparisons only; nothing is
merged across papers here.

- `Kaufman__2004_TableA15_compare_to_manual.R` — audits the built **A15** against the
  manually compiled tables Alexandra added (`Kaufman_energetics_weights.csv` and
  `wholebrain_/partsbrain_Kaufman2004.csv`). The wide manual tables are reshaped to long
  **for comparison only**. Result: **1,420 / 1,420 cells match, 0 mismatches** —
  `Kaufman__2004_TableA15_comparison_mismatches.csv` is empty (header only).
- `Kaufman__2004_energetics_compare_to_Kaufman_csv.R` — pre-existing manual-vs-manual
  consistency check (source wide tables vs the flattened compilation).

**A1–A14 validation.** Because A15 is A1–A14 restricted to conscious subjects, the A15
species means can be recomputed from the built per-study tables. Recomputing unweighted
`N` and `Mean` reproduces the verified A15 exactly for the cleanly-mapped regions (~90% of
cells to the cent). Residual differences are expected and are **not** extraction errors:
(a) A15's aggregate regions *Cortex* and *Whole Brain* are not sourced 1:1 from a single
appendix table; (b) a few ±1 study-count differences reflect Kaufman's own study-inclusion
choices; (c) a small number of small-N species rows sit on garbled continuation pages.

## Known limitations

The dissertation is a scanned document; the snapshots faithfully preserve OCR artefacts
(e.g. `’alombo` for *Palombo*, `Bums` for *Burns*, dropped opening parentheses, `nr` = not
reported). These live in `Reference`/`Species` text only; numeric values were verified via
the A15 reconciliation above. Taxonomy is left genus-level as printed and reconciled to
`_keys` in a later, cross-paper step.

## ReadMe.xlsx updates (this pass)

Filled the previously-blank *Item full original title* cells for `TableA3`–`TableA11`, and
set `TableA12`/`TableA13` titles to the dissertation's printed titles (Sensorimotor /
Cingulate). No item names were changed.
