# Lewitus et al. 2014 — Table S1 (physiological & life-history variables)

Lewitus E, Kelava I, Kalinka AT, Tomancak P, Huttner WB (2014). *An adaptive threshold in
mammalian neocortical evolution.* PLoS Biology 12(11):e1002000. doi:10.1371/journal.pbio.1002000

Table S1 = **"Physiological and life-history variables"** for 104 mammal species: brain/body/
neonate weights, neocortex volume, gyrification index (GI), ventricle volume, glia:neuron ratio,
neuronal & glial densities, basal metabolic rate, and ~30 life-history / ecology variables
(lifespan, gestation, litter size, diet, sociality, home range, …).

## Why this was (re)built
The dataset previously existed only as a hand-placed public TSV — there was **no snapshot, no
reformat script, and no analysis CSV**, so it wasn't reproducible and a set of header typos had
crept in. This build adds the full pipeline.

## Source → snapshot → CSV
- **Source:** journal supplement `pbio.1002000.s013.xlsx` (Table S1); kept in this folder.
  (Table S2 definitions = `pbio.1002000.s014.xlsx`; Table S9 neuron numbers = `pbio.1002000.s020.xlsx`.)
- **Snapshot:** `Lewitus_etal_2014_TableS1_snapshot.xlsx` (sheet `TableS1_snapshot`) — a **faithful**
  copy of the supplement, **including the journal's own header typos** (`Neuronal_denisty`,
  `Glial_cell_denisty`, `Basal_metaboic_rate`). Golden rule: the snapshot preserves the source
  verbatim; corrections happen in the reformat.
- **Reformat:** `Lewitus_etal_2014_TableS1.R` reads the snapshot, **corrects the three header typos**
  in the analysis output (→ `Neuronal_density`, `Glial_cell_density`, `Basal_metabolic_rate`),
  harmonises species (printed name kept as `Species`, accepted binomial added as `species_sci` via
  `_keys/Stephan/species_key.csv`), and writes:
  - `Lewitus_etal_2014_TableS1.csv` (analysis-ready, corrected names)
  - `__Public/comparative-data/10.1371%2Fjournal.pbio.1002000_TableS1.tsv`

## Species names
Printed (underscored) names preserved in `Species`; accepted binomials in `species_sci`. 74 of 104
species resolve to a canonical binomial already in `_keys/species_reference.csv`.

## Provenance note (glia variables)
The glia:neuron ratio and neuronal/glial density columns appear in this supplement (Table S1) but are
not discussed in the Lewitus 2014 main text; they trace to Lewitus et al. 2012
(doi:10.1111/j.1558-5646.2012.01601.x), where "glia" = astrocytes + oligodendrocytes. Kept as
**secondary** for those columns.

## Data role
`Body_weight`, `Brain_weight_g`, `Neonate_brain_weight_g` are **secondary** (compiled in the volume/
cell-count merges). The GI, neocortex, density, and life-history/ecology variables are **primary**
here. Registry: already in `__ReadMe.xlsx` as `Lewitus_etal_2014_TableS1`.

## Checks
- Analysis CSV = 104 rows (one per species). No independent curated copy to audit against, so no
  comparison script; the snapshot↔CSV diff is only the documented typo correction + `species_sci`.
