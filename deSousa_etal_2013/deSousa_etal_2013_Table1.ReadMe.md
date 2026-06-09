# deSousa_etal_2013_Table1

## Source
de Sousa, A. A., et al. (2013). Lamination of the lateral geniculate nucleus of catarrhine primates. Brain Behav Evol 81(2),93-108. Registry Item **Table 1**; DOI/PMID-coded TSV `10.1159%2F000346495_Table1.tsv`.

**lateral geniculate nucleus (LGN) lamination volumes.** Volumes in mm³ (body weight g, brain weight mg). Part of the **Stephan/Düsseldorf histological-volume collection**.

## Pipeline
raw → snapshot → R → usable csv/tsv. Files: `deSousa_etal_2013_Table1_snapshot.xlsx` (sheet `Table1`), `deSousa_etal_2013_Table1.R` → `deSousa_etal_2013_Table1.csv` (+ TSV), `reference_tables/deSousa_etal_2013_Table1_definitions.csv`, `comparison/deSousa_2013.csv` (curated source, audited).

Structures: Corpus geniculatum laterale.

## Preparation → `deSousa_etal_2013_Table1.csv`
One row per species. Values are taken from the curated comparison CSV `deSousa_2013.csv` (the audited journal data) and laid out journal-style in the snapshot; the reformat cleans names and types values (already mm³). Verified against the comparison CSV: **0 value mismatches**.

## Note
Snapshot built from the curated `deSousa_2013.csv`; detailed visual fidelity to the printed PDF table layout is a light follow-up (values are the audited source). Used in `__merging_volumes` (Tier 2 (averaged)).
