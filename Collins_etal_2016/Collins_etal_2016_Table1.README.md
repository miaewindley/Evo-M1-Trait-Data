# Collins et al. 2016 — Table 1 (one chimpanzee)

Collins CE, Turner EC, Sawyer EK, Reed JL, Young NA, Flaherty DK, Kaas JH (2016). *Cortical cell and
neuron density estimates in one chimpanzee hemisphere.* PNAS 113(3):740–745.
doi:10.1073/pnas.1524208113 · Team **Kaas** (Vanderbilt) · isotropic/flow fractionator.

Registry (`__ReadMe.xlsx`): Item **`Collins_etal_2016_Table1`**, encoded
`10.1073%2Fpnas.1524208113_Table1`.

## What the data are
Cell/neuron numbers and densities for **one hemisphere of one chimpanzee** (*Pan troglodytes*, female,
53 y, Texas Biomedical Research Institute), by cortical region: whole cerebral cortex (right, 341 cm²,
9.51 B cells, 3.71 B neurons, 39% neurons) plus V1, V2, a somatosensory block, M1, a premotor block,
and prefrontal cortex. 8 rows (one region per row; V1 also has a left-hemisphere serial-section volume).

## Source → Snapshot → Data readable
Values transcribed from the paper text/figures to `Collins_etal_2016_text_snapshot.xlsx`, frozen as
`Collins_etal_2016_Table1_snapshot.xlsx`. `Collins_etal_2016_Table1.R` →
`Collins_etal_2016_Table1.csv` (**use this**): counts converted to absolute numbers
(9.51 billion → 9.51e9), non-breaking spaces stripped, `% neurons` kept as a fraction. Columns in
`reference_tables/Collins_etal_2016_Table1_definitions.csv`.

## Specimen flag — likely the same chimp as Young 2013 (M1)
The `specimen_overlap` column marks every row: this chimpanzee is almost certainly the **same
individual** as the *Pan troglodytes* in **Young et al. 2013 (M1, folder `Young_etal_2013`)** — both
are the Kaas lab's single female chimpanzee obtained from the Texas Biomedical Research Institute. The
M1 surface area differs slightly (**2497 mm² here vs 2700 mm² in Young 2013**), consistent with
different M1 dissection boundaries rather than different animals. **Do not treat Collins 2016 and
Young 2013 as independent chimpanzees.**

## Merge note (not added)
This table is **not** added to `__merging_cortical_areas` here: its whole-cortex surface (341 cm² =
34,100 mm²) and M1 area (2497 mm²) would need explicit dedupe against Young 2013's chimp first. Left
as a deliberate decision. Same lineage as Collins 2010 (whole cortex per piece) and the other Kaas
tables — see the shared-specimen web.

Pipeline: Source → Snapshot ✅ → Data readable ✅ → Species note ✅ → Online database ✅
