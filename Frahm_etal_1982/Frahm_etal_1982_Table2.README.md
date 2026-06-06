# Frahm_etal_1982_Table2

## Source

PDF: `Stephan_temp_to_organize/pdfs/frahm_stephan_1982.pdf`. Paper: Frahm, H. D., & Stephan, H. (1982), *Comparison of brain structure volumes in Insectivora and Primates. I. Neocortex*, J. Hirnforsch. 23(4), 375-389. PMID 7161477.

This folder captures **Table 2** — the neocortex **volumes** (total, white matter, grey matter, lamina 1, laminae 2-6) — which is the table that matches `Frahm_1982.csv`. (Table 1 of the paper holds the *relative* measures and the total-neocortex size index; it is not snapshotted here, by design — see below.)

## Pipeline

raw → snapshot → R script → usable csv/tsv. The snapshot is cleaned only enough to read like the journal page; the R script does the rest (R-friendly names, superscript translation, fill-down, typing).

| Path | Role |
|---|---|
| `frahm_stephan_1982.pdf` (in shared pdfs/) | The publication. |
| `Frahm_etal_1982_Table2_snapshot.xlsx` | **Snapshot** (sheet `Table2`): Table 2 reproduced journal-style — caption, multi-tier header, taxonomic order via `group/family/species` columns, superscripts, group/subtotal/Mean rows, footnote legend. Volumes are from `Frahm_1982.csv`; the two % columns are computed. |
| `Frahm_etal_1982_Table2.R` | Preparation -> `Frahm_etal_1982_Table2.csv` (+ DOI/PMID-named TSV). Reads only the snapshot. |
| `reference_tables/Frahm_etal_1982_Table2_definitions.csv` | Data dictionary + the size-index method (5 structure-specific slopes). |
| `comparison/Frahm_1982.csv` | The formatted volumes table, audited only. |
| `comparison/Frahm_etal_1982_Table2_compare_to_Frahm_1982_csv.R` | Checking (QA): snapshot vs `Frahm_1982.csv`. |

## Why volumes only (not the size-index table)

The paper splits its data: **Table 1** = total-neocortex relative size (% of total brain weight / net brain / telencephalon) + size index; **Table 2** = the volumes. Your `Frahm_1982.csv` is the volumes (Table 2), so that is what the snapshot reproduces. The size indices are a deterministic function of these volumes and **body weights** (external to this table) via reference lines of fixed, structure-specific slope through the basal-Insectivora centroid — **total 0.67, white matter 0.86, grey matter 0.63, lamina 1 0.65, laminae 2-6 0.62** (recorded in the definitions). Recompute them in the downstream analysis where body weights are joined; the paper's printed Table 1 gives the total-neocortex index for validation.

## Snapshot layout

39 species with measured neocortex volumes, in taxonomic order. This set includes 7 Old-World monkeys/apes/human (Papio anubis, Cercopithecus ascanius, Colobus badius, Hylobates lar, Pan troglodytes, Pongo sp., Homo sapiens) that have neocortex but no AOB, so they are absent from the Stephan 1982 (AOB) table. The superscript former-name legend is **this paper's own** (e.g. 6 = Lemur fulvus, 11 = Cercopithecus talapoin) and differs from the AOB paper's numbering; only superscripts 1, 2, 6, 9 occur among the species with measured volumes.

## Preparation -> `Frahm_etal_1982_Table2.csv`

One row per species (39): `group, family, Species_Frahm1982, former_name_ref, former_name, n, total_neocortex_mm3, white_matter_mm3, white_pct_neocortex, grey_matter_mm3, lamina_1_mm3, lamina_1_pct_grey, laminae_2_6_mm3`. Current accepted names are applied later via `../_keys/Stephan/species_key.csv`. Also writes a DOI/PMID-named TSV to `../__Public/comparative-data/`.

## Checking -> `comparison/`

Matches snapshot to `Frahm_1982.csv` by species (on either the 1982 name or the canonical name, so the cleaned journal names still resolve) and compares the five volumes + n. Verified: **39 matched, 0 value mismatches.**

## Data note

`Frahm_1982.csv` carries a few OCR artifacts in `Species_Frahm1982` — `Microceblls murinus` (→ Microcebus murinus), truncated `Daubentonia madagascar.` (→ Daubentonia madagascariensis), and a blank name for Pongo. The snapshot uses the clean journal names; the comparison matches across them via the canonical name. Worth fixing at the source CSV.
