# deSousa_etal_2010_Table1

## Source
de Sousa, A. A., et al. (2010). Hominoid visual brain structure volumes... J Hum Evol 58(4),281-292. Registry Item **Table 1**; DOI/PMID-coded TSV `10.1016%2Fj.jhevol.2009.11.011_Table1.tsv`.

**hominoid visual brain structure volumes.** Volumes in mm³ (body weight g, brain weight mg). Part of the **Stephan/Düsseldorf histological-volume collection**.

## Pipeline
raw → snapshot → R → usable csv/tsv. Files: `deSousa_etal_2010_Table1_snapshot.xlsx` (sheet `Table1`), `deSousa_etal_2010_Table1.R` → `deSousa_etal_2010_Table1.csv` (+ TSV), `reference_tables/deSousa_etal_2010_Table1_definitions.csv`, `comparison/deSousa_2010.csv` (curated source, audited).

Structures: Neocortex, Area striata grey matter, Corpus geniculatum laterale, Total brain net volume.

## Preparation → `deSousa_etal_2010_Table1.csv`
One row per species. Values are taken from the curated comparison CSV `deSousa_2010.csv` (the audited journal data) and laid out journal-style in the snapshot; the reformat cleans names and types values (already mm³). Verified against the comparison CSV: **0 value mismatches**.

## Note
Snapshot built from the curated `deSousa_2010.csv`; detailed visual fidelity to the printed PDF table layout is a light follow-up (values are the audited source). Used in `__merging_volumes` (Tier 2 (averaged)).
