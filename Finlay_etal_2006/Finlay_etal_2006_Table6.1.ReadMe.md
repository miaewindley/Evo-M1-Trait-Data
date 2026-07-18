# Finlay et al. 2006 — Table 6.1

Finlay BL, Cheung DT, Darlington RB (2006). *Developmental constraints on or developmental structure
in brain evolution.* In: Munakata Y, Johnson MH (eds), *Attention and Performance XXI*, Oxford Univ.
Press. doi:10.1093/oso/9780198568742.003.0006

Table 6.1: per-species body/brain weight, number of visual / somatomotor / total cortical areas, and
total cortical sheet area. Values drawn primarily from the Kaas & Krubitzer mapping studies.

## Source → Snapshot
Publication PDF → Adobe "Export PDF → Excel" → Table 6.1 laid out by hand as
`Finlay_etal_2006_Table6.1_snapshot.xlsx` (`Common Name`, `Species Name`, then the six numeric
columns). Frozen/archival — all cleaning happens in the `.R`.

## Data readable
`Finlay_etal_2006_Table6.1.R` → `Finlay_etal_2006_Table6.1.csv` (**use this**). Numbers typed; the
journal's printed name kept verbatim in `species_as_published`; common name in `common_name`; a
canonical binomial in `Species`. Columns defined in
`reference_tables/Finlay_etal_2006_Table6.1_definitions.csv`.

## Species note (DONE)
The printed `Species Name` column mostly carries real binomials, but a few rows are genus-level
`sp.` or contain typos. Following the repo policy for these tables
(`__merging_volumes/SPECIES_STANDARDIZATION_PLAN.md` §3), a canonical **`Species`** column was added
and every decision recorded, with its basis, in the reviewable **`common_name_to_species.csv`**:

- **spelling fixes**: *Felis cattus*→*Felis catus*, *Tupia belangeri*→*Tupaia belangeri*.
- **CORRECTION**: the previous build renamed *Echinops telfairi*→"*Echinops telfari*" (a typo). That
  rename is removed — *telfairi* is correct and matches the rest of the repo.
- **re-identification of sp.-level labels**: "Rhesus Macaque" *Macaca sp.*→*Macaca mulatta*;
  "Squirrel" *Squirrel sp.*→*Sciurus carolinensis* (Krubitzer 1995; consistent with Changizi 2001).
- **kept at genus level** (clean single genus, species not pinned down): *Galago sp.*, *Mus sp.*
  (printed "Mouse sp."), *Rattus sp.* — with notes on the likely research-model species for review.

The printed names are never overwritten — they remain in `species_as_published`.

**Quality note (from the source):** this is a book chapter / conference volume; references are not
per-row, so the sp.-level assignments above are proposals for sign-off, not journal-stated facts.

Pipeline: Source → Snapshot ✅ → Data readable ✅ → Species note ✅ → Online database ✅
