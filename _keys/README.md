# _keys — shared references + per-team keys

These keys homogenize species names and anatomy terms across publications and carry current taxonomy. The design is **hub-and-spoke**: a small number of shared *reference* tables (the "third taxonomy" everything points to), and a separate *key* per team group that maps that collection's spellings/terms onto the references.

**Why keep teams separate (not one blended key):** the team groups are distinct specimen collections. Stephan/Frahm/Baron is one collection (mostly Düsseldorf); Herculano-Houzel is another, and its papers re-report **the same individuals** across tables. They should be *aligned* for cross-collection comparison via the shared references, never merged at the specimen level. Per-team keys also stay a manageable size as many more papers are added, and a new team group is just a new subfolder.

```
_keys/
  species_reference.csv      <- shared "third taxonomy" for species (the hub)
  anatomy_reference.csv      <- shared canonical structure vocabulary (the hub)
  Stephan/
    species_key.csv          <- Stephan spellings -> accepted_name
    anatomy_key.csv          <- Stephan structure codes -> canonical structure
  HerculanoHouzel/
    species_key.csv          <- HH spellings -> accepted_name (+ ncbi_taxid)
    anatomy_key.csv          <- HH raw terms -> standardized term
```

## Shared hubs

**`species_reference.csv`** — one row per canonical species (179). The single table both teams reference. Columns: `accepted_name` (the join anchor), `ncbi_taxid` (stable external ID; the third taxonomy's identifier), `in_Stephan` / `in_HerculanoHouzel`, the historical Stephan taxonomy (`Order_Stephan1981`, `Suborder_Stephan1981`, `Family_Stephan1981`, `code_Stephan1981`), the modern taxonomy (`Order_MDD`, `Family_MDD`, `mdd_accepted_name` — filled for the Baron species so far), and `needs_taxonomy_review` (TRUE where no modern order is assigned yet). 85 rows carry an NCBI taxid; 13 species are measured by both collections.

**`anatomy_reference.csv`** — the canonical structure vocabulary (181 structures), `domain`-tagged: 92 `cell_counts` (English terms, e.g. `OlfactoryBulb`) + 89 `brain_structure_volume` (Latin Stephan terms, e.g. `Bulbus_olfactorius`), with the measures seen per structure.

## Per-team keys

Each maps a collection's raw labels to the hub; it never references the other team.

- **`Stephan/species_key.csv`** (1,010 variant rows): `accepted_name`, `source_publication`, `variant_name` — every spelling seen in the Stephan-collection papers.
- **`Stephan/anatomy_key.csv`** (247 rows): `reference`, `canonical_structure`, `measure`, `anatomy_code`, `original_column` — each volume paper's structure code/header mapped to a canonical Latin structure (harvested from each paper's `AAAA_Anatomy_code` row across 20 volume papers). E.g. `Bulbus_olfactorius` is coded `11` in Stephan 1981, `BOL` in Baron 1987, and `MOB` in Baron 1983.
- **`HerculanoHouzel/species_key.csv`** (87): `accepted_name`, `ncbi_taxid`, `variant_name`, `source_datasets`.
- **`HerculanoHouzel/anatomy_key.csv`** (871): `standardized_term`, `structure`, `measure`, `original_term_variant`, `reference` — each paper's raw column header mapped to a canonical structure + measure.

## How to use it (at the compilation step)

A paper's species name → look up in its team's `species_key.csv` → `accepted_name` → `species_reference.csv` (taxonomy, NCBI taxid). A paper's structure label → its team's `anatomy_key.csv` → `standardized_term` → `anatomy_reference.csv`. Adding a paper = adding rows to its team's key (and any new species/structures to the shared reference). Adding a team = a new subfolder.

## Provenance & follow-ups

Built from `__merging_cellcounts/` (`cellcounts_source_species_ids.csv`, `standardized_term_cellcounts.csv`), `Stephan_temp_to_organize/csvs/Species_Codes.csv`, the harvested Stephan name variants, and the Baron 1983/1987 MDD crosswalks.

Open: (1) **taxonomy-currency pass** — run `resolve_taxonomy.R`, which fills current `Order_resolved` / `Family_resolved` for all 179 from **NCBI Taxonomy first** (by taxid where present, else by name), falling back to **ITIS** then **GBIF**, recording the source and flagging any disagreement with the existing MDD order. (NCBI's eutils API was not reachable from the build sandbox, so this is a script to run in your environment.) (2) resolve **NCBI taxids** for the Stephan-only species so every row has the stable ID; (3) **cross-domain structure harmonization** — map the Latin volume structures to the English cell-count structures within `anatomy_reference.csv` (e.g. `Bulbus_olfactorius` <-> `OlfactoryBulb`) so the two collections' structures can be compared.
