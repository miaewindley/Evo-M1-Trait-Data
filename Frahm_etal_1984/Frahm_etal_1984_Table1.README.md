# Frahm_etal_1984_Table1

## Source
Frahm, H. D., Stephan, H., & Baron, G. (1984). Comparison of brain structure volumes... area striata. Registry Item **Table 1**; DOI/PMID-coded TSV `PMID%3A6501869_Table1.tsv`.

**area striata (primary visual cortex, V1) volumes.** Volumes in mm³ (body weight g, brain weight mg). Part of the **Stephan/Düsseldorf histological-volume collection**.

## Pipeline
raw → snapshot → R → usable csv/tsv. Files: `Frahm_etal_1984_Table1_snapshot.xlsx` (sheet `Table1`), `Frahm_etal_1984_Table1.R` → `Frahm_etal_1984_Table1.csv` (+ TSV), `reference_tables/Frahm_etal_1984_Table1_definitions.csv`, `comparison/Frahm_1984.csv` (curated source, audited).

Structures: Area striata, Area striata grey matter, Area striata lamina 1, Area striata laminae 2 6, Area striata white matter.

## Preparation → `Frahm_etal_1984_Table1.csv`
One row per species. Values are taken from the curated comparison CSV `Frahm_1984.csv` (the audited journal data) and laid out journal-style in the snapshot; the reformat cleans names and types values (already mm³). Verified against the comparison CSV: **0 value mismatches**.

## Note
Snapshot built from the curated `Frahm_1984.csv`; detailed visual fidelity to the printed PDF table layout is a light follow-up (values are the audited source). Used in `__merging_volumes` (Tier 1 (Stephan collection, most-recent-date)).
