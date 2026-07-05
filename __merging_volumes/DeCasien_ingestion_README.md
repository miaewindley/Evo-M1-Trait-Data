# Ingesting DeCasien & Higham 2019 into the canonical volume merge

This document describes how the canonical merge (`volumes_compiled.R` → `volumes_long.csv` /
`volumes_wide.csv` / `volumes_unfiltered.csv`) systematically absorbs the volumetric data compiled by
DeCasien & Higham 2019, and how to keep it growing as new DeCasien versions are released.

## Principle: DeCasien is a compilation, not a measurement

DeCasien & Higham 2019 is a **compilation of primary sources**, not an independent measurement series.
So it must **fill gaps, never double-count**. If a DeCasien cell reproduces a primary that is already
in the merge, ingesting DeCasien as if it were its own dataset would average that same specimen in
twice. Primaries therefore always win; DeCasien is ingested only where nothing else covers a
species × structure.

The merge's own two-tier engine (see `README__merging.md`) enforces this: the Stephan collection is
Tier 1 (one evolving series, newest wins), every independent lab is its own Tier-2 team, and across
teams the surviving values are **averaged**. DeCasien enters this as one more Tier-2 team, `DeCasien`,
but only for genuine gaps.

## The status → action ladder

Every DeCasien cell is classified by the comparison script
(`DeCasien_Higham_2019/DeCasien_Higham_2019_SupplementaryData1-BrainRegion.R`) into a `status`. That
status dictates what the merge does with it:

| DeCasien cell status | meaning | action |
|---|---|---|
| `match` / `match_taxonomy_variant` / `species_mean_match` | a primary already in the merge carries this value | **nothing** — already covered |
| `decasien_only`, a primary exists in the corpus but isn't wired in | e.g. Bush 2004a before this change | **ingest the primary** (best: real specimen data, own team) |
| `decasien_only`, primary is wired but a crosswalk/derivation is missing | e.g. a GM+WM sum not computed | **fix the crosswalk / reshape** in `volumes_compiled.R` |
| `decasien_only`, no primary anywhere in the corpus | genuinely new coverage | **ingest the DeCasien mean as team `DeCasien`** (the gap-fill mechanism) |
| duplication / cross-genus misattribution | e.g. Disco/GPZ-5542 | **skip** — scripted reclassification in the comparison |
| `description_match_value_mismatch` | a primary covers it but DeCasien's value disagrees | **flag, do not auto-ingest** — needs human review |

Preference order: **wire the primary > fix a derivation > ingest DeCasien mean**. Ingesting the
DeCasien compiled mean is the last resort, used only when no primary in the corpus measures that
species × structure at all.

## How the gap-fill mechanism works (and why it can't double-count)

1. The comparison script writes `DeCasien_Higham_2019/DeCasien_gapfill_candidates.csv`: every DeCasien
   cell that (a) maps to a canonical term, (b) is not the Disco duplicate, (c) is not a value-mismatch,
   and (d) has **no non-DeCasien merge source** measuring that species × structure. Coverage is tested
   against primaries **only** (any `Source` not starting `DeCasien`).
2. `volumes_compiled.R` step **4b** reads that file and appends its rows to the long table as team
   `DeCasien` (Source `DeCasien2019_MOESM3_meanvalue`, Year 2019), with an `anti_join` guard that drops
   any row a primary already provides. They then flow through the same Tier-2 cross-team average as
   every other team.

**Idempotence.** Because the emitter tests coverage against primaries only, injecting the DeCasien-team
value on one run does not change the gap set on the next — the merge↔comparison loop is stable and
cannot oscillate or double-count. As new primaries are wired in, the cells they cover drop out of the
gap-fill file automatically on the next comparison run.

As of the current DeCasien version the gap-fill file is **empty** (0 rows): every DeCasien cell is
covered by a primary or is the excluded Disco duplicate. The mechanism is in place for future versions.

## Offline reproducibility (taxizedb cache)

Species resolution (step 4) normally uses `taxizedb` against a live NCBI taxonomy dump. When taxizedb
or the network is unavailable, the script falls back to the committed backbone cache
`volumes_species_ids_cache.csv` (raw name → NCBI id/name), so the merge regenerates without network.
The cache is **refreshed automatically only on a successful live run**; a cache-driven run never
overwrites it (that would be circular). If the cache is missing a raw name the run stops with a clear
message — refresh it with one live taxizedb run.

> **Locale note.** Run with a UTF-8 locale (`LC_ALL=en_US.UTF-8`). Some registry item names contain
> non-ASCII characters (e.g. `Zilles_Rehkämper_1988`); under `LC_CTYPE=C` the item-name match fails.
> RStudio uses UTF-8 by default; a bare `Rscript` may not.

## Re-run steps when a new DeCasien version is dropped in

1. Replace `DeCasien_Higham_2019/41559_2019_969_MOESM3_ESM.xlsx` with the new supplement (same sheet
   name `Brain Region Data (mm3)`), and update the region crosswalk (`xwalk`) if new regions appear.
2. Run `volumes_compiled.R` (rebuilds the merge; step 4b picks up any existing gap-fill file).
3. Run the comparison script (rebuilds `DeCasien_vs_merge_comparison.csv` and, crucially, rewrites
   `DeCasien_gapfill_candidates.csv`).
4. **Review the new `decasien_only` rows** in the comparison. For each, walk the ladder:
   - primary in the corpus but unwired → add it to the `papers` tribble (+ `enc_override`, + a reshape
     branch if unit/derivation conversion is needed), as was done for Bush 2004a;
   - primary wired but a derivation missing → fix the reshape/crosswalk;
   - no primary anywhere → it is now in `DeCasien_gapfill_candidates.csv` and will be ingested as team
     `DeCasien` on the next `volumes_compiled.R` run.
5. Re-run `volumes_compiled.R` once more if you wired a new primary or a new gap-fill appeared, then the
   comparison, and confirm `decasien_only` shrank and nothing flipped `match` → mismatch
   (`DeCasien_ingestion_checks.csv`).

Newly-added primaries progressively **replace** DeCasien-team gap-fills: once a primary covers a
species × structure, that cell leaves the gap-fill file and the merge sources it from the primary
instead. The dataset grows and improves with each DeCasien release without ever double-counting.

## Files

| file | role |
|---|---|
| `volumes_compiled.R` | canonical merge; papers tribble, Bush 2004a reshape, taxizedb cache fallback, step 4b gap-fill consumer |
| `volumes_species_ids_cache.csv` | offline NCBI backbone cache (raw → NCBI id/name) |
| `DeCasien_Higham_2019/DeCasien_Higham_2019_SupplementaryData1-BrainRegion.R` | comparison + Disco override + gap-fill emitter |
| `DeCasien_Higham_2019/DeCasien_vs_merge_comparison.csv` | per-cell comparison (the classification that drives the ladder) |
| `DeCasien_Higham_2019/DeCasien_gapfill_candidates.csv` | cells to ingest as team `DeCasien` (currently empty) |
| `DeCasien_ingestion_report.md` | before/after coverage report + chart |
| `DeCasien_ingestion_checks.csv` | integrity / no-regression checks |
| `____Collections and Specimen notes/Disco_gibbon_specimen_note.md` | the Disco/GPZ-5542 cross-genus provenance note |
