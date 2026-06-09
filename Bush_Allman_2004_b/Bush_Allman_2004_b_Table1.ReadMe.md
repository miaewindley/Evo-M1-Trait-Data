# Bush & Allman 2004 — Table 1 (V1 and rest of brain, primates)
Bush EC, Allman JM (2004). *Three-dimensional structure and evolution of primate primary visual cortex.* Anat Rec A 281(1):1088-1094.
Full title (`__ReadMe.xlsx`): **"Table 1. Measurements in V1 and the rest of the brain for a sample of primates"**
## Source->Snapshot
PDF p.3 (text layer). `..._Table1_snapshot.csv` = 21 species x V1G, LGN, V1surf, Hmerid, Wb, NeoW, NeoG.
## Data readable
`..._Table1.R` -> `..._Table1.csv`/`.tsv`: species harmonized; columns renamed (V1_grey_cm3, LGN_cm3, V1_surface_cm2, horizontal_meridian_mm, whole_brain_cm3, neocortex_white/grey_cm3).
## Comparisons (comparison copy/)
- `check_Table1_vs_compiled.csv` vs your `bush_compiled.xlsx`: **92/95 cells match**.
- `compare_V1_Bush_vs_deSousa.csv`: V1 grey vs your de Sousa V1 (`ASG_Sousa`), 11 shared species - **large divergences** (Pan +33%, Macaca -39%, Aotus -37%; Homo +6%). Confirms V1 measurements differ substantially by source; pick one consistently for Study 3.
Pipeline: Source->Snapshot OK->Data readable OK->Species harmonized->Online database
