# Specimen crosswalk & taxon-concept registry (`_keys/specimen_crosswalk/`)

Cross-paper harmonisation keys at the **specimen** and **taxon-concept** level,
analogous to `_keys/Stephan/species_key.csv` but finer-grained. This directory
solves two *different* problems that were being conflated; see `SCHEMA.md` for
the full column contracts.

## The two layers (why there are two)

| problem | example | file | mechanism |
|---|---|---|---|
| **one individual, many labels** | gibbon *Disco* / GPZ-5542 — one animal, published as *H. lar*, *N. concolor*, studbook *N. leucogenys* | `specimen_crosswalk.csv` | one `canonical_specimen`; resolve to one identity via `resolved_taxon` |
| **one label, many individuals** | pre-2001 *"Pongo pygmaeus"* mean — Bornean + Sumatran (+ hybrid) pooled | `taxon_concept_registry.csv` | pin the value to a `taxon_concept` (`s.l.`); never un-average |

A specimen can be **reassigned** as taxonomy changes; a pooled *sensu lato*
mean **cannot be split** into modern species without fabricating composition the
source never resolved. That asymmetry is the whole reason for two files.

## Files

| file | contents |
|---|---|
| `SCHEMA.md` | authoritative column contracts + the join + the merge consumer rule. |
| `specimen_crosswalk.csv` | living-collection specimens (one row per individual × source label). Extends the fossil pattern below. |
| `taxon_concept_registry.csv` | taxonomic concepts, esp. old broad (`s.l.`) concepts, with `decomposable` and `believed_composition`. |
| `collection_specimens_parsed.csv` | the master catalog (`specimens info 151211.xls`, 181 specimens) parsed to identity/provenance columns; `taxon_flag` marks disagreements. |
| `collection_specimens_parsed.COLUMNMAP.md` | column map for the above. |
| `pongo_provenance_audit.csv` | every place a Pongo value enters the merge/comparison, classified specimen vs pooled-concept. |
| `fossil_specimen_crosswalk.csv` | the original fossil crosswalk (Kochiyama/Weaver); the template this generalises. |
| `fossil_specimen_cerebellum_comparison.csv` | fossil method-offset comparison. |

## The join

```text
specimen_crosswalk.taxon_concept  ->  taxon_concept_registry.taxon_concept
```

A specimen row's `taxon_concept` says which concept its **printed** label
belonged to; the specimen's own best identity is `resolved_taxon` and may differ
(YN85-38 is printed under `Pongo pygmaeus (s.l.)` but resolved to `Pongo abelii`).

## The hard rule for the merge (consumer contract)

The volume merge (`__merging_volumes/volumes_compiled.R`) and the DeCasien
comparison must honour:

1. **Specimen measurement** → may be reassigned to a modern species via
   `resolved_taxon`, always surfacing `taxon_conflict` (never silent).
2. **Pooled mean under an `s.l.` concept** with `decomposable = FALSE` →
   **never auto-rewritten** to a modern species. Stays under its concept label;
   at most annotated with `believed_composition`.

### How this differs from the DeCasien cross-genus duplicate case

The Disco case in the DeCasien ladder is a **duplicate**: *one* specimen
double-entered under two genera → resolve by dedup (scripted override in the
comparison). A `sensu lato` pooled mean is the opposite: *many* specimens under
*one* label → do **not** split. Both are taxon/identity hazards, but the actions
are opposite. Keep them distinct:

```text
cross-genus duplicate  (Disco)        -> dedup to one specimen
sensu lato pooled mean (Pongo s.l.)   -> keep pooled, pin to concept
```

## Worked reference example: Pongo (orangutan)

Full write-up: `../../____Collections and Specimen notes/Pongo_specimen_note.md`.

*Pongo* was one species (*P. pygmaeus s.l.*) before Groves (2001) and is now two
(*P. pygmaeus s.s.* Bornean + *P. abelii* Sumatran). In this dataset:

- The **master catalog** lists 9 orangutans all as `Pongo pygmaeus`, but two
  (CAT-150, CAT-151) carry a `subspecies` value (`abeli`, `sumatra`) showing
  they are Sumatran — hidden from any species-column-only pipeline.
- **MacLeod 2000** records specimen **YN85-38** as `PONGO PYGMAEUS / ABELII` —
  the explicit pygmaeus→abelii reassignment, resolved to *P. abelii*.
- The orangutans are **Zilles/Yerkes** material housed at the **Düsseldorf**
  Vogt Institut alongside the Stephan collection; house names tie the systems
  together (catalog *Harry*=MacLeod OY 1148; catalog *Briggs*=MacLeod OHDZ). This
  is why a Pongo value can appear in a Stephan-dataset comparison having come
  from the Zilles/Rehkämper stream.
- **Zilles/Rehkämper 1988** records Pongo honestly as `Pongo sp.` (genus-level);
  **DeCasien** promotes that to modern `Pongo pygmaeus` — flagged in the audit
  as a broad-concept value that should stay pinned to `Pongo pygmaeus (s.l.)`.
- **DeCasien `Pongo_abelii`** (from Bauernfeind) is correct modern data and must
  **not** be merged with pre-2001 `Pongo pygmaeus` values as if the same taxon.

## Adding a new specimen / concept case

1. If it is one individual with conflicting labels → add rows to
   `specimen_crosswalk.csv` (one `canonical_specimen`, one alias row per source);
   set `resolved_taxon` only with evidence; set `taxon_conflict` when sources
   disagree. Write a specimen note in `____Collections and Specimen notes/`.
2. If it is an old broad label over a pooled sample → add/point at a row in
   `taxon_concept_registry.csv` with `sensu = s.l.` and `decomposable = FALSE`.
3. Audit where its values enter the merge (mirror `pongo_provenance_audit.csv`).
