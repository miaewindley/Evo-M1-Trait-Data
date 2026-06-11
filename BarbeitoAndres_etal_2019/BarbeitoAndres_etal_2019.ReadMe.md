# Barbeito-Andres et al. 2019 (developmental / experimental mouse dataset)
Barbeito-Andres J, et al. (2019). *Region-specific changes in Mus musculus brain size and cell
composition under chronic nutrient restriction.* Journal of Experimental Biology.

## Separate comparison set (NOT in the volume merge)
Single species (Mus musculus) under experimental nutrition groups. This is a developmental/
experimental dataset, kept as its own comparison set; it is **not** part of the phylogenetic
volume merge in `__merging_volumes/`.

## Source -> Snapshot
`data_figshare.xlsx` sheet **Hoja1** only (Hoja2 and Hoja3 are empty). Hoja1 stacks three
sub-tables, frozen here as three faithful snapshots:
- `..._volumes_snapshot.csv`     - Absolute volumes (mm3), per specimen, 13 regions incl Total.
- `..._cellnumber_snapshot.csv`  - Cell number, per animal, 5 region groups x {Total, Neurons, Non-neurons}.
- `..._celldensity_snapshot.csv` - Cell density, same layout.
Groups: **C** = control, **LP** = low protein, **LCP** = low calorie + protein (labels as published).

## Data readable
`BarbeitoAndres_etal_2019.R` -> `BarbeitoAndres_etal_2019_tidy.csv`: one tidy long table aligned to a
generic developmental schema `species, reference, group, specimen, region, cell_type, measure, value,
units`. `measure` in {absolute_volume (mm3), cell_number, cell_density}.

## NEEDS USER VERIFICATION
- **Cell-count / density units & scaling**: the figshare sheet does not state units explicitly.
  Volumes are mm3 (Total ~ 365-380 mm3 for a mouse brain -> consistent). Cell *number* values
  (~25-45) are almost certainly in **millions (x1e6)** and cell *density* (~500-1000) likely
  **cells per mg** (cf. Herculano-Houzel 'N mg-1'). Confirm against the paper before any analysis.
- The cell tables label rows by group only (no specimen id); confirm per-animal correspondence to the
  volume table if pairing is needed.

Pipeline: Source -> Snapshot OK -> Data readable OK -> units/scaling verification (pending) -> standalone comparison set.
