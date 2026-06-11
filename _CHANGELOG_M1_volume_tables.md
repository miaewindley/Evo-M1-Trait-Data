# Evo-M1-Trait-Data — M1 volume-tables milestone (summary for maintainer)

Builds on the `cleanup-laterality-tables` baseline (277×107, 25 tables, 108 flags). All R run on
R 4.5.2 via an external path-rewriting runner, so committed scripts keep their OneDrive `setwd()` and
the repo diff stays clean. **No commit/push.** These 65 files are staged in `upload_Evo-M1-Trait-Data/`
(same relative paths) plus this changelog.

## Result
Volume merge: **277 species × 117 variables, 29 tables, 108 flags**, laterality guard OK (20 one-side
columns). +10 variables / +4 tables vs baseline; flags unchanged.

---

## Part I.C — Audit
`__merging_volumes/_audit_missing_structures.{R,csv}` + `_audit_missing_structures.FINDINGS.md`.
Confirmed **Barger amygdala subnuclei** as the only true missing-structure case; the rest are
laterality sub-parts, SEM columns, or definition-naming artifacts.

## Part I.B — Volumes added to the merge (all verified)
| Paper | team | added |
|---|---|---|
| Barger 2007 subnuclei | Zilles | Amygdala basolateral division, lateral / basal / accessory-basal nuclei, + Cerebral_hemispheres (both-hemisphere `_total`, cm³→mm³) |
| Bush & Allman 2004_b | Bush | V1 grey→Area_striata_grey_matter, LGN→Corpus_geniculatum_laterale, whole brain→Total_brain_net_volume, neocortex grey/white |
| Semendeferi 1998 | Semendeferi | Area_13_right (orbitofrontal, n=1) |
| Semendeferi 2001 | Semendeferi | Area_10_right (frontal pole, n=1) |
| Sherwood 2005 | Sherwood | Medulla (reuses Stephan term, cross-validates ~1%), Trigeminal_motor/Facial_motor/Hypoglossal nuclei (left) |

Notes: Barger BLD ≈ lateral+basal+accessory; `Amygdala_Vol.mm3` average unchanged. Semendeferi
brain-volume columns deliberately NOT merged (n=1 remeasurements of Stephan specimens → would
double-count). One-side columns registered in `laterality_known.csv`; species harmonized via a new
`Semendeferi` token (Sherwood_2005 token already existed).

## Part I.A — Folder builds
- **Sherwood 2005** — built to the 4-file convention from the PDF.
- **Sherwood 2004_I** — completed; **GLI / M1 cytoarchitecture, not volume** → not merged.
- **Semendeferi 1998/2001/2002** — verified; **2002 = percentages only** → not merged.
- **Stephan, Bauchot & Andy 1970** (Insectivores & Primates; DeCasien ref 51) — see below.

### Stephan 1970 — COMPLETE transcription, DRAFT pending verification (NOT merged)
- The repo's `____Brain_structure_volumes/Stephan-1970-…` PDF is a different paper (Stephan & Pirlot
  1970, *bats*). The correct PDF is now in `Stephan_etal_1970/stephan_etal_1970.pdf`.
- PDF text layer + figshare xlsx were corrupted OCR. **All 6 tables (63 species)** transcribed from
  300-dpi page renders: Tables 1–3 = body/brain weight + 5 fundamental sections; Tables 4–6 = 7
  telencephalon components. (The paper has only 6 tables — no Tables 7–9; "percentage" on p.7 is
  discussion text, not a table.)
- Two validations: (a) cross-check vs the existing merge — several EXACT cells, rest within ~1–2%;
  (b) the 7 components sum to the Telencephalon total to **max 0.35%, median 0.006%, 0 species >1%**.
- Flagged cell: Saguinus oedipus total → 9576 (verify). Caveat: column 10 is Palaeocortex+amygdala
  (could not be separated in 1970) → mapped to a distinct `Palaeocortex_plus_amygdala_Vol.mm3`; do not
  merge with the later `Palaeocortex_Vol.mm3`.
- Activation steps in `Stephan_etal_1970/Stephan_etal_1970.ReadMe.md`. As the oldest Stephan table it is
  superseded by 1981+ in Tier-1, so net merge impact is small.

## Part II — DeCasien & Higham 2019 comparison + taxonomy
Rewrote `DeCasien_Higham_2019_SupplementaryData1-BrainRegion.R` (was incomplete/hardcoded). Value-matches
every DeCasien cell vs the merge (same genus, 2% tol) with an anatomy crosswalk + Stephan ref-ids.
- `DeCasien_vs_merge_comparison.csv`: 2152 cells → **923 exact**, 270 taxonomy-variant, 289 other, 670
  DeCasien-only.
- `DeCasien_taxonomy_proposed_changes.csv`: 6 species_key edits proposed (e.g. Lagothrix lagotricha→
  lagothricha, Gorilla gorilla gorilla→Gorilla sp.) — **for review, not applied**.
- `DeCasien_Higham_2019_FINDINGS.md`: practices to borrow; flags an AOB term fragmentation.

## Part III — Barbeito-Andrés 2019 (developmental, separate set)
`BarbeitoAndres_etal_2019.R` parses Hoja1 (Hoja2/3 empty) → 3 snapshots + `..._tidy.csv` (Absolute
volumes / Cell number / Cell density; groups C/LP/LCP). **Cell-count/density units need verification.**
Not in the volume merge.

## Part IV — Energetics
Heiss 2004 completed to convention. `__energetics_comparison/` unifies Heiss (human CMRgl) + Kaufman
2004 (12 species, CMRgl/CMRO2/CBF) → `energetics_long.csv` + `ENERGETICS_FINDINGS.md` (human cortical
CMRgl agrees: Heiss 33.0 vs Kaufman 37.5). Karbowski 2007 has garbled-OCR xlsx → described, needs a
dedicated parse. **A merge schema is proposed for your confirmation before any energetics merge.**

## Still blocked (absent from repo & Downloads)
Stimpson 2015, Rilling & Insel 1998, Barks 2014/2015 — rechecked at finish; still missing.

---

## WHAT TO UPLOAD
Everything in `~/Desktop/upload_Evo-M1-Trait-Data/` (65 repo files, original folder structure, + this
changelog). Zip the folder and upload as-is.

### Modified (10) — the real review targets
- `__merging_volumes/volumes_compiled.R` (Barger reshape, Bush 2004_b, Semendeferi rows, enc_override)
- `__merging_volumes/standardized_term_by_reference/Barger_etal_2007_TABLE1_standardized_terms.csv`
- `__merging_volumes/laterality_known.csv`
- `_keys/Stephan/species_key.csv` (Semendeferi token)
- `DeCasien_Higham_2019/DeCasien_Higham_2019_SupplementaryData1-BrainRegion.R`
- regenerated merge outputs: `standardized_term_volumes.csv`, `volumes_long.csv`, `volumes_wide.csv`,
  `volumes_unfiltered.csv`, `volumes_source_species_ids.csv`

### New (55) — grouped
- Audit: `__merging_volumes/_audit_missing_structures.{R,csv,FINDINGS.md}`
- New term maps: Bush_Allman_2004_b, Semendeferi 1998/2001, Sherwood 2005 (in standardized_term_by_reference/)
- New TSVs in `__Public/comparative-data/` (Sherwood 2005 DOI-coded; Semendeferi 1998/2001)
- New paper-folder files: Sherwood 2005, Sherwood 2004_I, Heiss 2004 (defs+ReadMe), Barbeito 2019,
  Stephan 1970 (PDF, 6 table images, 2 DRAFT snapshots, combined Tables1-6 csv/tsv, defs, READY term
  map, ReadMe, raw-text)
- DeCasien outputs (comparison CSV, taxonomy proposals, FINDINGS)
- `__energetics_comparison/` (script, energetics_long.csv, FINDINGS)

## Action items for you
1. Verify **Stephan 1970** DRAFT, then activate per its ReadMe.
2. Review **DeCasien** taxonomy proposals before editing species_key.
3. Verify **Barbeito** cell-number/density units.
4. Confirm the **energetics** merge schema.
5. Add `__ReadMe.xlsx` rows for Semendeferi 1998/2001 (they use an `enc_override` fallback for now).
