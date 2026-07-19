# Lewitus et al. 2013 — Table 1 (a.k.a. Suppl. Table S2, partial)

Lewitus E, Kelava I, Huttner WB (2013). *Conical expansion of the outer subventricular zone and the
role of neocortical folding in evolution and development.* Frontiers in Human Neuroscience 7:424.
doi:10.3389/fnhum.2013.00424

Brain weight, neuron density, astrocyte density, grey-matter thickness, lateral-ventricle volume,
and gyrification index (GI) for 66 mammal species.

## This is a composite table (mostly re-used data)
Per the paper's own note, the columns come from three sources:

- **Brain weight** and **ventricle (1 & 2) volume** → Stephan et al. 1981 (already in the volume merge)
- **Neuron density** and **astrocyte density** → Lewitus et al. 2012
- **GI** → Lewitus et al. 2013 (this paper)

So most columns are **secondary / re-used**; only the grey-matter thickness and GI are treated as
primary here. Data role in `__ReadMe.xlsx` should be **both** (or **secondary**), and it is **not**
merged as new brain-weight/ventricle data (that would double-count Stephan 1981).

## Source → snapshot → CSV
- **Source:** the table is published as an image (`fnhum-07-00424-t001.jpg`); the values were
  transcribed. The article PDF (kept here) carries the same table.
- **Snapshot:** `Lewitus_etal_2013_TableS2partial_snapshot.xlsx` (sheet `TableS2partial_snapshot`) —
  frozen transcription (66 species; the density columns are **sparsely filled**, 27–40/66, exactly as
  in the source — hence "partial").
- **Reformat:** `Lewitus_etal_2013_TableS2partial.R` cleans column names, harmonises species (printed
  name kept as `Species`, accepted binomial in `species_sci`), and writes:
  - `Lewitus_etal_2013_TableS2partial.csv`
  - `__Public/comparative-data/10.3389%2Ffnhum.2013.00424_TableS2partial.tsv`

## Species names
Printed names preserved; all 66 resolve to a binomial. Four printed typos/abbreviations were mapped
in `_keys/Stephan/species_key.csv` (source `Lewitus2013`): `Macaca mulata`→*M. mulatta*,
`Mustelaa putorius`→*Mustela putorius furo*, `Hydrochoerus h.`→*H. hydrochaeris*,
`Daubentonia m.`→*D. madagascariensis*.

## Numbering note
The project encoded name is `…_TableS2partial` (kept to match the registry); in the article the table
is printed as **Table 1**.
