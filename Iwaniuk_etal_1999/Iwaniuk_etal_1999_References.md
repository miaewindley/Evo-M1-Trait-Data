# Iwaniuk et al. 1999 — Reference list

Iwaniuk AN, Pellis SM, Whishaw IQ (1999). *Is digital dexterity really related to corticospinal
projections?: a re-analysis of the Heffner and Masterton data set using modern comparative
statistics.* Behav Brain Res 101(2):173–187. doi:10.1016/s0166-4328(98)00151-x

The paper's numbered reference list, kept as a lookup table for the `Depth_Ref` / `Length_Ref`
columns in `Iwaniuk_etal_1999_Table1`.

## Source → Snapshot
Reference section copied from the PDF into plain text (`Iwaniuk_etal_1999_References.txt`);
spacing and special characters repaired.

## Data readable
`Iwaniuk_etal_1999_References.R` → `Iwaniuk_etal_1999_References.csv` (**use this**). Splits the
text on the `[N]` markers into `ref_number` + `citation`, normalises whitespace, sorts by number
(69 references). Columns defined in
`reference_tables/Iwaniuk_etal_1999_References_definitions.csv`.

## Usage
Join `Iwaniuk_etal_1999_Table1` `Depth_Ref` / `Length_Ref` to `ref_number` here to recover the
original source for each anatomical measurement.

Pipeline: Source → Snapshot ✅ → Data readable ✅ → Online database ☐ (reference list; not a
species-trait table, so no TSV is published to `__Public/comparative-data/`)
