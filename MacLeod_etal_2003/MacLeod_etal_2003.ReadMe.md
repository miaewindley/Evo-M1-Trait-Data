# MacLeod et al. 2003 — cerebellum / vermis / hemisphere volumes

MacLeod CE, Zilles K, Schleicher A, Rilling JK, Gibson KR (2003).
*Expansion of the neocerebellum in Hominoidea.* Journal of Human Evolution 44(4):401–429.
doi:10.1016/S0047-2484(03)00028-9 · PMID 12727461

## Source

PDF in repo root (`macleod_etal_2003.pdf`). Two per-specimen volumetric tables:
- **Table 1** — Yerkes sample (p. 409): 47 specimens.
- **Table 2** — Hirnforschung sample (p. 410): 50 specimens.
Both report, per specimen: Sex, Brain volume, Cerebellum volume, Vermis volume, Hemisphere
volume (all cm³).

## Snapshot

Extracted from the PDF text layer with `pymupdf` (page 9 = Table 1, page 10 = Table 2) and
written verbatim:
- `MacLeod_etal_2003_Table1_Yerkes_snapshot.csv`
- `MacLeod_etal_2003_Table2_Hirnforschung_snapshot.csv`

Faithful to the print: original column headers (with `cm3` units), specimen IDs, **footnote
markers kept in the Specimen cell**, and `NA` exactly where printed. Row order preserved.
Row counts verified against the paper (47 and 50). *Recommend a visual diff against the PDF
before publication use (text-layer extraction, not hand-typed).*

Footnote legend (from Table 2):
- `†` specimen **from the Stephan Collection**
- `‡` post-mortem brain weight not known
- `*` horizontal sections   ·   `§` sagittal sections   ·   (default: coronal)

## Data readable

`MacLeod_etal_2003.R` turns the snapshots into:
- `MacLeod_etal_2003.csv` — **USE THIS** — 97 specimens × clean columns. Volumes → numeric;
  the footnote markers are decoded into explicit columns: `stephan_collection` (from `†`),
  `brainweight_known` (from `‡`), `section_plane` (from `*`/`§`). `sample` = Yerkes / Hirnforschung.
- `MacLeod_etal_2003_species_means.csv` — per-species means + `n` + `n_stephan_collection`.
  This is the **merge-ready** table that joins to the species-level Stephan volumes.

## Species note (IN PROGRESS)

Binomials are taken as printed; still to reconcile against `_keys/Stephan/species_key.csv`:
- `Cebus apella` → likely `Sapajus apella`
- `Cercocebus torquatus atys` (subspecies kept)
- `Cebus sp.`, `Cercopithecus sp.` — unresolved to species.

## Provenance / why this source

Primary measurements (MRI + histological sections). Per the team note that the **Zilles and
Stephan collections are now housed together and combined across papers**, the `†` Stephan-
Collection specimens are the **same brains** as Stephan/Frahm — so those can in principle be
matched specimen-to-specimen; the Yerkes specimens (and other Hirnforschung cases) are separate
brains and merge at the species-mean level. Fills the **Vermis** and **Cerebellar cortex** rows
of the Heiss-2004 correspondence with true per-species volumes (not proportion-derived).

## Pipeline status

Source → Snapshot ✅ → Data readable ✅ → Species note ⏳ → Online database ☐
