# Stephan_etal_1981_Table1

## Source

PDF: `Stephan-1981-New and revised data.pdf`. Paper: Stephan, H., Frahm, H. D., & Baron, G. (1981), *New and revised data on volumes of brain structures in insectivores and primates*, Folia Primatologica 35, 1-29.

This is the **master volume table** of the Stephan/Frahm/Baron collection and the dominant source feeding the `Stephan_primates` compilation (approximately 43 of its traits). It reports volumes of approximately 44 brain structures for 76 species (Insectivora, Macroscelidea, Scandentia, and Primates).

## Pipeline

raw -> snapshot -> R script -> usable csv/tsv.

| Path | Role |
|---|---|
| `Stephan-1981-New and revised data.pdf` | The publication. |
| `Stephan_etal_1981_Table1_snapshot.xlsx` | **Snapshot** (sheet `Table1`): 76 species in Stephan code (taxonomic) order x the 44 structures, in the journal's code order, with the 6 per-range `n` columns. Values from the curated `Stephan_1981` dataset. |
| `Stephan_etal_1981_Table1.R` | Preparation -> `Stephan_etal_1981_Table1.csv` (+ DOI/PMID-named TSV). Reads only the snapshot. Adds explicit laterality suffixes to the unilateral vestibular columns. |
| `reference_tables/Stephan_etal_1981_Table1_definitions.csv` | Data dictionary: each structure -> code, anatomy, measure, role, taxon. |
| `comparison/Stephan_1981.csv` | The formatted dataset, audited only. |
| `comparison/Stephan_etal_1981_Table1_compare_to_Stephan_1981_csv.R` | Checking (QA): snapshot vs `Stephan_1981.csv`. |

## Snapshot layout

A wide table: `code`, `species`, then the 44 structure-volume columns interleaved with the 6 sample-size columns `n (1-18)`, `n (19-26)`, `n (27-28)`, `n (29-34)`, `n (35-39)`, `n (40-44)`, exactly the structure-code groups the journal uses. Each structure header carries its Stephan code in parentheses. **Units:** body weight in g, brain weight in mg, all structure volumes in mm3. Species run in Stephan code order (Solenodon = 1 ... Homo sapiens = 280), which is the journal's taxonomic sequence.

Note: in the printed paper this table is paginated across several pages by structure-code group; the snapshot consolidates those into one sheet in the same order so it can be read and compared as a whole. Taxonomic section headers (Basal Insectivora, Progressive Insectivora, ..., Prosimians, Simians) are implicit in the code order and can be added as label rows later if wanted.

## Laterality note: Stephan 1981 vestibular structures are unilateral

The 1981 paper lists the vestibular complex and four component nuclei as codes 35-39 in Tables XII and XIII. The paper itself does not label those table values as unilateral. However, Baron, Frahm & Stephan (1988), *Comparison of Brain Structure Volumes in Insectivora and Primates. VIII. Vestibular Complex*, later states that the vestibular nucleus volumes in Stephan et al. (1981) were measured in 39 species **from one side only**, whereas the 1988 vestibular data were new measurements **from both sides**. Therefore the Stephan 1981 values below should be treated as measured unilateral volumes, not bilateral volumes.

The script leaves the numeric values unchanged and makes the laterality explicit by appending `_unilateral` to only these five output columns:

| Stephan code | Journal structure | Output column |
|---:|---|---|
| 35 | Complexus vestibularis | `Complexus_vestibularis_unilateral` |
| 36 | Nucleus vestibularis superior | `Nucleus_vestibularis_superior_unilateral` |
| 37 | Nucleus vestibularis lateralis | `Nucleus_vestibularis_lateralis_unilateral` |
| 38 | Nucleus vestibularis medialis | `Nucleus_vestibularis_medialis_unilateral` |
| 39 | Nucleus vestibularis descendens | `Nucleus_vestibularis_descendens_unilateral` |

Use `_unilateral` rather than `_hemisphere`: these are brainstem vestibular nuclei, so "hemisphere" could be misread as cerebral hemisphere. The source does not specify left versus right side. For a bilateral approximation, compute `2 * value` downstream and flag it, e.g. `estimated_bilateral_from_unilateral = TRUE`; do not overwrite the original unilateral measurements.

## Preparation -> `Stephan_etal_1981_Table1.csv`

One row per species (76); journal headers cleaned to R-friendly names (`Body_weight`, `Total_brain_net_volume`, `Neocortex`, ..., plus `n_1_18` etc.), all measurements typed numeric. Current accepted names + taxonomy are applied downstream via `../_keys/Stephan/`. Also writes a DOI/PMID-named TSV to `../__Public/comparative-data/`.

Schema note: the five vestibular output columns now carry the `_unilateral` suffix listed above. Other structure-volume columns are not relabeled as unilateral.

## Checking -> `comparison/`

Matches the snapshot to `Stephan_1981.csv` by species and compares every shared structure column. Verified: **76 species, 44 structure columns, 0 cell mismatches** (the snapshot is assembled from this CSV, so this confirms faithful assembly; the `n` columns are carried from the CSV but named differently, so they are not part of the value audit).
