# Lewitus et al. 2014 — Table S8 (neocortical neuron number, Figure 3d)

Lewitus E, Kelava I, Kalinka AT, Tomancak P, Huttner WB (2014). *An adaptive threshold in
mammalian neocortical evolution.* PLoS Biology 12(11):e1002000. doi:10.1371/journal.pbio.1002000

Neocortical **neuron number** and **gyrification index (GI)** for 25 mammal species (the data behind
Figure 3d).

## Numbering note
The supplement download (`…s020`) is registered and cited in this project as **Table S8**
("Neocortical neuron number for Figure 3d"), but the spreadsheet's own title cell reads
**"Table S9"**. The item name is kept as `Lewitus_etal_2014_TableS8` to match the registry and the
public encoded name; the discrepancy is recorded here and in the definitions.

## Source → snapshot → CSV
- **Source:** `pbio.1002000.s020.xlsx` (kept in this folder).
- **Snapshot:** `Lewitus_etal_2014_TableS8_snapshot.xlsx` (sheet `TableS8_snapshot`) — faithful copy
  (keeps the "Table S9" title cell and the full-precision integer neuron counts).
- **Reformat:** `Lewitus_etal_2014_TableS8.R` harmonises species and writes:
  - `Lewitus_etal_2014_TableS8.csv`
  - `__Public/comparative-data/10.1371%2Fjournal.pbio.1002000_TableS8.tsv`

## Fix applied
The previous public TSV stored neuron counts in **rounded scientific notation** (`1.42E+07`); this
build restores the **full-precision integers** from the source (`14200000`), matching the QA rule for
regenerating rounded/decimal-dropped public tables.

## Species / role
Printed names preserved in `Species`; accepted binomials in `species_sci` (18/25 resolve to a
canonical binomial). `Neuronal_number` is **primary**; `GI` is **secondary** (also in Table S1).
