# Baron_etal_1983_Table1

## Source

PDF: `baron_etal_1983.pdf`

Paper: Baron, G., Frahm, H. D., Bhatnagar, K. P., and Stephan, H. (1983). *Comparison of Brain Structure Volumes in Insectivora and Primates. III. Main olfactory bulb (MOB).* Journal fuer Hirnforschung 24:551-568.

Table: **Table 1. Data on total MOB (layers 1-6 + periventricular zone).**

The source table spans PDF pages 3-5 in the local file render (`page-03.png`, `page-04.png`, `page-05.png`).

## Snapshot

`Baron_etal_1983_Table1_snapshot.xlsx`, sheet `Table1_snapshot`.

This workbook is the faithful capture layer. It preserves the original table orientation and labels from the PDF: original species names and abbreviations, original four-digit code numbers, asterisk markers in `n`, plus-sign markers on selected volumes, the group/means headings, and the footnotes below the table. Row 1 is the caption, row 2 is the header, rows 3+ are data.

Do not use the snapshot directly for analysis. Use it as the auditable representation of the PDF table. Both R scripts read it directly from the `.xlsx` (no intermediate snapshot CSV).

## Scripts

Both scripts are written in **tidyverse** (`readxl`, `readr`, `dplyr`, `tidyr`, `stringr`, `tibble`). Install once with `install.packages(c("tidyverse", "readxl"))`. Run from this folder (set the working directory here first).

### 1. Comparison / audit — `Baron_etal_1983_Table1_compare_to_Baron_1983_csv.R`

Reads the snapshot `.xlsx` and `Baron_1983.csv`, matches rows by the Baron 1983 code, and compares `n` and MOB volume numerically. The CSV's updated binomial (`Species`) is treated as an intentional improvement and is never a mismatch; the original label (`Species_Baron1983`) is compared against the snapshot.

Writes:

- `Baron_etal_1983_Table1_comparison_report_from_R.csv` — every matched/unmatched row with match flags.
- `Baron_etal_1983_Table1_comparison_mismatches_from_R.csv` — only rows needing attention.

Current result: all 76 species match by code with **0 `n` mismatches and 0 volume mismatches**. Two original-name transcription typos in the CSV are surfaced for review: code 0589 `Oryzoricles talpoides` (snapshot `Oryzorictes talpoides`) and code 3244 `Avahi I. occidentalis` (snapshot `Avahi l. occidentalis`).

> **Bug fixed in this version.** `Baron_1983.csv` contains a non-UTF-8 byte (`0xCA`, a Mac-Roman non-breaking space) inside *Scutisorex somereni*. The previous reader tried UTF-8 first; R hit the bad byte, emitted a **warning** (not an error), and silently truncated the read there — dropping the 12 species below that line. Because it was a warning, the `tryCatch()` latin1 fallback never fired, so those species (Tenrec, Suncus, Tupaia, Tarsius, etc.) were wrongly reported as "missing from csv". The CSV is now read with `readr::locale(encoding = "latin1")`, which reads every byte.

### 2. Analysis-ready table — `Baron_etal_1983_Table1.R`

Reads the snapshot `.xlsx` and writes `Baron_etal_1983_Table1.csv`: one row per species (76 rows), with

- numeric value columns (`n`, volume, SEM %, size index, per-mille of net brain, per-mille of telencephalon); dashes/blanks become `NA`;
- note markers split into their own columns (`Number_of_individuals_note` = `*`, `Bulbus_olfactorius_note` = `+`) so the value columns stay numeric;
- the trailing Baron footnote digit captured in `Species_Baron1983_footnote`;
- two taxonomic columns — `Major_group` (Insectivora, Scandentia, Primates, Macroscelidea) and `Subgroup` (e.g. Basal/Progressive Insectivora, Prosimians, Simians) — carried down from the section headings via a small lookup that encodes the paper's hierarchy;
- updated binomials in `Species`, matched from `Baron_1983.csv` by code (the same latin1 fix applies); the original PDF label is kept in `Species_Baron1983`.

Values always come from the snapshot, never from the CSV.

## Notes on standardization

- `MOB` is standardized to `Bulbus_olfactorius` in value-bearing column names, matching the convention in `Baron_1983.csv`.
- The original anatomical label is preserved as `Structure_original = total MOB (layers 1-6 + periventricular zone)`.
- The `Major_group` species counts (Insectivora 26, Primates 45, Scandentia 3, Macroscelidea 2) match the N totals in the paper's own Means rows, confirming the grouping.
