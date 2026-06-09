# Smaers_etal_2017_TableS1_part2_surfacearea

## Source

PDF: `Smaers-2017-Exceptional Evolutio.pdf`; supplement `mmc1.pdf` (publisher Excel
`Smaers_mmc1.xlsx`, sheet "Table 1"; also the standalone file `cortical surfaces Brodmann 1909 in
Smears et al 2017.xlsx`). Paper: Smaers, J. B., Gómez-Robles, A., Parks, A. N., & Sherwood, C. C.
(2017). *Exceptional Evolutionary Expansion of Prefrontal Cortex in Great Apes and Humans.* Curr
Biol 27(5), 714–720. https://doi.org/10.1016/j.cub.2017.01.020

This is **part 2 of 2** of supplemental **Table S1** — the **"Brodmann data" surface-area block**:
4 cortical regions (primary visual, prefrontal, other cortical association areas, frontal motor),
**surface area in mm²**, 10 primate species. (Part 1 = the Smaers volume block; see
`Smaers_etal_2017_TableS1_part1_volumes.README.md`.)

## Files

| Path | Role |
|---|---|
| `Smaers_etal_2017_TableS1_part2_surfacearea_snapshot.xlsx` | **Snapshot** (sheet `surface_area`): Table S1's Brodmann block journal-style (caption; "Surface area" tier-1 span; the 4 region sub-headers; 10 species). Values from `Smaers_mmc1.xlsx`. |
| `Smaers_etal_2017_TableS1_part2_surfacearea.R` | Reformat → `Smaers_etal_2017_TableS1_part2_surfacearea.csv` (+ DOI-named TSV). Reads only the snapshot. |
| `reference_tables/Smaers_etal_2017_TableS1_part2_surfacearea_definitions.csv` | Data dictionary (10-col schema; `Measure = surface area`). |
| `comparison/Brodmann_surface_1909.csv` | Independent formatted surface-area table (from `cortical surfaces Brodmann 1909 in Smears et al 2017.xlsx`), audited only. |
| `comparison/Smaers_etal_2017_TableS1_part2_surfacearea_compare_to_Brodmann_csv.R` | QA: snapshot vs `Brodmann_surface_1909.csv`. |
| `__Public/comparative-data/10.1016%2Fj.cub.2017.01.020_TableS1part2surfacearea.tsv` | Shared public copy. |

## Provenance

Surface areas are from **Brodmann (1909) [S3]** (granular/agranular cytoarchitectonic criteria),
reproduced in Smaers 2017 Table S1. Only **9 of 10** species carry all four regions; *Saimiri
sciureus* has primary visual only (printed blank elsewhere — kept blank).

## Reformat → CSV

The R reads past the 3 header rows, names the 5 columns by position, drops empty rows, underscores
the species name, adds `source = "Smaers_etal_2017"`, and writes the CSV plus a DOI-named TSV. (R is
not in the build sandbox; the committed CSV/TSV were produced by a Python mirror of this exact logic
and will be regenerated when you run the R.)

Output columns: `species, primary_visual_surface, prefrontal_surface, other_association_surface,
frontal_motor_surface, source`.

## Checking → `comparison/`

Snapshot (built from `Smaers_mmc1.xlsx`) matched by species to `Brodmann_surface_1909.csv` (built
from the *independent* publisher file `cortical surfaces Brodmann 1909 in Smears et al 2017.xlsx`).
A clean match across the two independent digitisations confirms the transcription. **Verified: 10
matched, 0 value mismatches, no snapshot-only / csv-only species.**
