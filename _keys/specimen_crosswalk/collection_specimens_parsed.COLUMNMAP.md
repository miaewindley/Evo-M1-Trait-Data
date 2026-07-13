# collection_specimens_parsed.csv — column map

Parsed from `____Collections and Specimen notes/specimens info 151211.xls`,
sheet `catalog` (header row 1; 181 specimen rows after dropping blank rows;
the source sheet has 102 columns, most of them per-structure measurements).

This file carries the **identity / provenance** columns only. The measurement
columns (brain vol, cerebellum, LGN, V1, …) stay in the source spreadsheet and
are pulled per-paper by the normal build scripts; this is a specimen registry,
not a volume table.

## Columns kept (verbatim from the sheet unless noted)

| column | source sheet column | note |
|---|---|---|
| `canonical_specimen` | — (minted) | `CAT-###` by catalog row order; one per physical specimen row. |
| `record_type` | — | always `specimen`. |
| `collection` | `collection` | holding collection. |
| `wherelocated`,`located` | `wherelocated`,`located` | physical whereabouts. |
| `species` | `species` | primary printed binomial. |
| `other sp.` | `other sp.` | alternate species label the catalog also lists. |
| `subspecies` | `subspecies` | **where the pygmaeus/abelii + sumatra cases hide.** |
| `source` | `source` | provenance (Yerkes, etc.). |
| `Art. Nr.`,`Tier Nr.` | same | institutional accession numbers. |
| `Frahm Species` | `Frahm Species` | Frahm-dataset label. |
| `other code`,`Macleod code`,`my working code`,`inst code`,`simple code`,`box slide catalog code` | same | the various code systems. |
| `name or nickname` | `name or nickname` | house name (links to MacLeod/studbook). |
| `Sex`,`Age (Yr)` | same | |
| `taxon_flag` | — (derived) | disagreement flag (see below). |

## `taxon_flag` values (derived, 17 rows)

- `sumatran-in-pygmaeus` — subspecies field says `abeli`/`sumatra` while species
  says `Pongo pygmaeus`; i.e. a modern *P. abelii* individual hidden in the flat
  *P. pygmaeus* label (CAT-150, CAT-151).
- `subspecies-mismatch` — subspecies epithet differs from the species epithet
  (e.g. *Gorilla gorilla* / East lowland; *Pan troglodytes schweinfurthi*).
- `alt-species-listed` — `other sp.` lists a different (usually older) binomial
  for the same specimen (e.g. *Eulemur fulvus* / *Lemur fulvus*).

These flags mark rows that need a specimen- or concept-level decision before the
label is trusted in a merge. The Pongo rows are worked through in
`specimen_crosswalk.csv` + `taxon_concept_registry.csv`.
