# Merging cell-counts data

Pipeline for compiling the comparative brain cell-count dataset.

## Steps

1. **Standardized term list** — `standardized_term.R`
   - Input: one term file per table in `standardized_term_by_reference/`
     (`<Reference>_standardized_terms.csv`, columns `Original_Term, Reference, Standardized_Term`).
   - Output: `standardized_term_cellcounts.csv` (all per-reference files stacked).

2. **Compile cell counts** — `cellcounts_compiled.R`
   - Merges, filters, and calculates variables across datasets.
   - Inputs: `__Public/comparative-data/*.tsv`, `__ReadMe.xlsx`, `standardized_term_cellcounts.csv`.
   - Outputs: `cellcounts_long.csv`, `cellcounts_wide.csv`.
   - Checks: `cellcounts_unfiltered.csv`; `cellcounts_conflictcheck.R`.
   - Species names: `cellcounts_source_species_ids.csv`.
   - Flagged datasets: `*_metadata_flags.csv`.

3. **Imputations** — `cellcounts_imputations_diagnostic.R` → `imp30x10.RData`.

## Adding a paper

1. Create `standardized_term_by_reference/<Reference>_standardized_terms.csv` (its terms → standardized terms).
2. Register it in `__ReadMe.xlsx` (Item name → Item encoded) and add it to the `item_name` vector in `cellcounts_compiled.R`.
3. Put its DOI-coded table in `__Public/comparative-data/<Item encoded>.tsv`.
4. Re-run `standardized_term.R`, then `cellcounts_compiled.R`.

Most recent addition: `AvelinodeSouza_etal_2025_TABLE1` (*Balaenoptera acutorostrata*, the minke whale).

## Corrections

- **2026-06 — HH-2020 Table 2 derived masses (unit fix), step 3.4.**
  Regional masses not reported in Herculano-Houzel et al. 2020 Table 2
  (`CerebralCortex_Mass.g`, `Cerebellum_Mass.g`, `RoB_Mass.g`) are back-calculated
  from neuron count ÷ neuronal density. Because `_N.p.mg` is neurons per **mg**,
  `_N.n / _N.p.mg` is a mass in **mg** and must be divided by 1000 to get grams.
  The code previously **multiplied** by 1000, inflating those masses by **10⁶** for
  the ~13 African bats in that table (whole-brain masses, reported directly, were
  unaffected). Corrected to `(_N.n / _N.p.mg) / 1000`. Re-run the pipeline to
  propagate the fix.

- **2026-06 — Burish et al. 2010 (two fixes).**
  (a) *Brain = whole brain*: Burish's "Brain" (`MBR`, `NBR`) is the whole brain, so it is now
  mapped to `WholeBrain_Mass.g` / `WholeBrain_N.n` in its standardized-terms file (rather than a
  separate `Brain_*` measure that duplicated WholeBrain). The `Brain_*` measure no longer exists.
  (b) *Units*: Burish tabulated cell COUNTS in **millions** (e.g. *Macaca mulatta* brain "6380" =
  6.38×10⁹ neurons; spinal-cord neuron/other counts likewise). Step 3.4b in `cellcounts_compiled.R`
  now multiplies `WholeBrain_N.n`, `SpinalCord_N.n(_SD)`, `SpinalCord_O.n(_SD)` by 1e6. Masses (g),
  densities (per mg) and percentages were already absolute and are unchanged. A density sanity scan
  (neurons / (mass×1000) should be ~50–3,000,000 /mg) flagged only Burish; JardimMesseder et al. 2017
  and the other datasets were within range. Re-run `standardized_term.R` then `cellcounts_compiled.R`.
