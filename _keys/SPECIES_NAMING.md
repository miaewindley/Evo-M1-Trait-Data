# Species naming — one way for the whole dataset

**Status:** proposed design (no code changed yet). This spec defines a single, shared way to
resolve species names so the *same per-paper table* can feed any sub-dataset (volumes, cell counts,
metabolic, …) and get **the same accepted name every time**. Review this, then we migrate the code.

It refines the hub-and-spoke design already described in `_keys/README.md` — that design stays;
this fixes the part that drifted (two resolution mechanisms and two key schemas).

---

## 1. The problem we're fixing

Today a species name is resolved in **two different ways**, so the same species can come out
differently depending on which sub-dataset it lands in:

- **Volumes** (`__merging_volumes/volumes_compiled.R`, step 4) maps each paper's printed name through
  `_keys/Stephan/species_key.csv` using a per-paper `token` and an `accepted(token, name)` function.
  It reads **only the Stephan key** (not Allman or HerculanoHouzel).
- **Cell counts** (`__merging_cellcounts/cellcounts_compiled.R`, step 4) ignores the spoke keys and
  resolves names with a **live NCBI `name2taxid()` lookup** to an NCBI "preferred name".
- A few per-paper build scripts (the `Bush_Allman_*` ones) *also* harmonise in-script, against
  whichever key directory they happen to point at (`Stephan` in one, `Allman` in others).

Three schemas/paths for one job. The two merges can disagree; the per-paper scripts add a third path.

---

## 2. Principles (the "one way")

1. **One join anchor, many taxonomy views.** `_keys/species_reference.csv` holds the single
   internal **identity** for each animal — `accepted_name` (the join anchor) backed where possible by
   a `ncbi_taxid`. This anchor is *not* a taxonomy claim; it is just the stable key everything joins
   on. **Taxonomy** (Order/Family/rank, and the "accepted" binomial under a given authority) is a
   *separate, multi-valued* attribute kept in `species_taxonomy.csv` — one row per
   `(accepted_name × authority)`, so the same animal can carry NCBI, ITIS, GBIF, MDD, and even
   paper-specific names at once (see §3 and §6/R1). Nothing downstream invents its own mapping or
   does a live taxonomy lookup at compile time; it picks an existing authority view.
2. **Resolve once, at the merge/compile step — never in the per-paper build.** Per-paper tables keep
   only the **printed** name. Each sub-dataset calls the *same* resolver. (This is the choice we
   made: it is what lets one per-paper TSV be reused across sub-datasets unchanged.)
3. **Key the variant map by paper, not by lab or by table.** Each variant row is identified by
   `(source_publication, variant_name)`, where **`source_publication` is the paper = its folder
   name** (`Stephan_etal_1981`), not the per-table Item name. A paper belongs to one collection, so
   its variant rows live in that collection's spoke file **once**, and every table of that paper and
   every sub-dataset that uses it resolves through those same rows. **One paper → one taxonomy** by
   default (see §6/R3); a paper that genuinely mixes taxonomies must say so explicitly (a per-table
   override row), never silently.
4. **One resolver function, called identically everywhere.** Both merges (and any future one)
   `source()` the same `_keys/resolve_species.R` and call one function. No bespoke per-merge logic.
5. **Keep the per-collection spoke files** (the README's reasons hold: collections are distinct
   specimen sets, files stay a manageable size, a new collection is just a new subfolder) — but give
   them **one identical schema** so they can be stacked into a single variant table.

---

## 3. The pieces

```
_keys/
  species_reference.csv        HUB / IDENTITY — one row per accepted_name (+ default ncbi_taxid)
  species_taxonomy.csv         TAXONOMY CROSSWALK (NEW) — one row per (accepted_name x authority)
  resolve_species.R            the single resolver (NEW) — sourced by every merge
  <Collection>/
    species_key.csv            SPOKE — variant spellings -> accepted_name (unified schema)
```

### 3a. Hub / identity — `species_reference.csv`

One row per canonical animal = the **join anchor**. Keep it lean and identity-focused:
`accepted_name` (anchor) and a single default `ncbi_taxid`. It may retain the convenience taxonomy
columns it has today (`Order_resolved`, `Family_resolved`, the historical `*_Stephan1981`, the
`*_MDD`), but those are now understood as a *default view*; the full, multi-authority taxonomy lives
in `species_taxonomy.csv`. Adding a new species = one new row here (plus its variant row in the
relevant spoke, and its authority rows in the crosswalk).

### 3a-bis. Taxonomy crosswalk — `species_taxonomy.csv` (NEW, supports R1)

The multiple-taxonomy table. **One row per `(accepted_name × authority)`:**

```
accepted_name, authority, authority_name, authority_id, rank, order, family, note
```

- `authority` — `NCBI`, `ITIS`, `GBIF`, `MDD`, or `paper:<folder>` for a paper-specific taxonomy
  (e.g. `paper:DeCasien_Higham_2019`).
- `authority_name` — the accepted binomial **under that authority** (may differ from our anchor).
- `authority_id` — that authority's stable ID (NCBI taxid, ITIS TSN, GBIF key, MDD id, …).
- `rank` — `species` / `genus` / `subspecies` (lets a genus-level `sp.` carry a genus id honestly).
- `order`, `family`, `note` — taxonomy under that authority + provenance.

This is what lets you "convert to multiple taxonomies": a record keyed on `accepted_name` can be
relabelled into *any* authority's name/rank/order by joining this table on the chosen `authority`.
`resolve_taxonomy.R` populates the `NCBI`/`ITIS`/`GBIF` rows; MDD and `paper:*` rows are added by
hand or from a paper's own table. For one-off cases you can look an authority up live **once** and
cache the result here, so the pipeline stays offline thereafter.

### 3b. Spokes — `<Collection>/species_key.csv` (UNIFIED schema)

**Target schema — identical in every spoke:**

```
variant_name, accepted_name, source_publication, collection, ncbi_taxid, note
```

- `variant_name` — the name exactly as printed in that paper (the thing we match on).
- `accepted_name` — the canonical name; must exist in `species_reference.csv`.
- `source_publication` — the **paper = folder name** (`Stephan_etal_1981`), shared by all tables of
  that paper (decided in §6/R3). Not the per-table Item name.
- `collection` — the spoke group (`Stephan`, `Allman`, `HerculanoHouzel`, …). Redundant with the
  folder, but explicit so stacked rows stay self-describing.
- `ncbi_taxid` — optional convenience copy; the authoritative taxid lives in the hub.
- `note` — free text (e.g. "typo in print", "combined species", "former name").

**Current vs target:**

| spoke | current columns | change needed |
|---|---|---|
| `Stephan/species_key.csv` (1038) | `accepted_name, source_publication, variant_name` | add `collection`, `ncbi_taxid`, `note`; reorder |
| `Allman/species_key.csv` (121) | `accepted_name, source_publication, variant_name` | same as Stephan |
| `HerculanoHouzel/species_key.csv` (87) | `accepted_name, ncbi_taxid, variant_name, source_datasets` | split `source_datasets` (comma list) into one row per `source_publication`; add `collection`, `note` |

### 3c. Resolver — `_keys/resolve_species.R` (NEW)

A small file that loads once and exposes one function. **Proposed contract:**

```r
# resolve_species(printed, source_publication = NULL,
#                  taxonomy = "NCBI",
#                  return = c("accepted_name","authority_name","authority_id","rank","order","family"))
#
#   printed             character vector of names as printed in the source table
#   source_publication  the paper = folder name (so the same spelling in two papers can map
#                        differently if ever needed); if NULL, match on variant_name alone
#   taxonomy            which authority view to attach: "NCBI" (default) | "ITIS" | "GBIF" |
#                        "MDD" | "paper:<folder>" | "anchor" (= our accepted_name only, no relabel)
#   return              which field(s) to attach
#
# Behaviour:
#   1. bind ALL _keys/*/species_key.csv into one variant table (cached)
#   2. match (source_publication, variant_name) -> accepted_name        [IDENTITY: always single]
#      (fall back to variant_name-only match; then to the printed string itself)
#   3. join species_taxonomy.csv on (accepted_name, authority = taxonomy) [TAXONOMY: selectable]
#      to attach that authority's name / id / rank / order / family
#   4. return a data.frame aligned to `printed`, with `unresolved` (no accepted_name) and
#      `taxonomy_missing` (accepted_name found but no row for that authority) flags
```

Step 2 is the **identity** step — always one `accepted_name`, so every sub-dataset joins
consistently. Step 3 is the **taxonomy** step — swap `taxonomy=` to relabel the same records into
NCBI, MDD, a paper's taxonomy, etc., without changing the join. This generalises the volumes merge's
existing `accepted(token, name)` helper (which already does steps 1–2 against a single spoke) to read
**all** spokes and attach a chosen authority. The cell-counts merge's live `name2taxid()` block
becomes `resolve_species(..., taxonomy = "NCBI")` (the NCBI names/ids come from the crosswalk, looked
up once and cached — not re-fetched every run).

---

## 4. The resolution flow

```
per-paper build (e.g. Bush_Allman_2003_Table1.R)
    -> writes TSV with the PRINTED name only (species_as_published / Species_<Paper>)
       (NO harmonisation in the per-paper script)

merge / sub-dataset (volumes, cell counts, metabolic, …)
    -> source("_keys/resolve_species.R")
    -> Species_accepted <- resolve_species(printed, source_publication = <token>)
    -> join, dedupe, average, etc. on accepted_name
```

Because every sub-dataset runs the same call on the same printed name, a table reused in two
sub-datasets resolves identically by construction.

---

## 5. How to … (once migrated)

- **Add a paper.** Build it (printed name only in the TSV). Add its variant rows to the relevant
  `<Collection>/species_key.csv` (one row per printed spelling → accepted name). If it introduces a
  species not yet in the hub, add one row to `species_reference.csv` (with `ncbi_taxid` if known) and
  re-run `resolve_taxonomy.R`. Add the paper to the sub-dataset's `item_name`/`papers` list. Done —
  it now resolves the same way in every sub-dataset.
- **Add a new sub-dataset.** `source()` the resolver and call `resolve_species()`. No new naming code.
- **Add a new collection.** New `_keys/<Collection>/species_key.csv` with the unified schema; the
  resolver picks it up automatically (it globs `_keys/*/species_key.csv`).
- **Fix a misidentified/typo'd name.** Edit the spoke row (and `note`), never the per-paper TSV.

---

## 6. Migration checklist (when we proceed)

1. **Unify the spoke schema.** Add the missing columns to Stephan/Allman; expand HerculanoHouzel's
   `source_datasets` list into one row per `source_publication`. Verify no `accepted_name` is absent
   from `species_reference.csv`.
2. **Write `_keys/resolve_species.R`** implementing §3c; unit-check it against a handful of known
   (paper, printed)→accepted pairs from each collection.
3. **Repoint `volumes_compiled.R`** to `source()` the resolver and replace the local `accepted()` +
   single-key read. Re-run; **diff `volumes_long.csv` against the pre-migration copy — expect zero
   changes** (volumes already uses the Stephan key, so this should be behaviour-preserving).
4. **Repoint `cellcounts_compiled.R`** to use the resolver instead of `name2taxid()`. Re-run; diff
   `cellcounts_long.csv` and **review every species whose name changes** — this is where the old
   NCBI-preferred-name path and the new accepted_name path may differ (see R1).
5. **Remove in-script harmonisation** from `Bush_Allman_2003/2004_a/2004_b` (and don't add it to new
   scripts): keep `species_as_published` only. Move their mappings into `Allman/species_key.csv`.
6. **Update the HOWTO §5** to state the single rule: per-paper scripts keep the printed name; the
   merge resolves via `resolve_species()`.

### Risks / decisions to settle first

- **R1 — cell-counts name changes.** The cell-counts merge currently trusts NCBI's preferred name.
  Some species may resolve to a *different* `accepted_name` under the hub. The diff in step 4 must be
  reviewed by you; any genuine disagreements get reconciled in `species_reference.csv`
  (`accepted_name` vs `mdd_accepted_name`/NCBI) before we cut over.
- **R2 — taxid coverage.** Cell-counts steps want a taxid for every species; the hub has ~85/179.
  Fill taxids for the cell-count species in `species_reference.csv` before retiring `name2taxid()`,
  or have the resolver fall back to a one-off NCBI lookup *only for missing taxids* (and write them
  back to the hub, so it converges and stays offline thereafter).
- **R3 — the join key.** Volumes uses short tokens (`Stephan1981`); the registry/build uses long
  Item names (`Stephan_etal_1981_Table1`). Pick **one** as `source_publication` in the spokes and as
  the resolver's argument. Recommendation: the **Item name** (matches `__ReadMe.xlsx` and the TSV
  filenames), with the old tokens kept only as an alias column if needed during transition.
- **R4 — variant-name collisions.** If the same `variant_name` maps to different accepted names in
  two papers, the `(source_publication, variant_name)` key handles it — but flag any such case so
  it's a deliberate decision, not a silent overwrite.

---

## 7. Comparison datasets & taxonomy reconciliation

Some datasets are not *primary sources* we merge — they are external **benchmarks** we compare the
merge against (e.g. **DeCasien & Higham 2019**). The naming design covers them, but they play a
different role, and they expose the one thing the resolver deliberately does **not** do
automatically: taxonomic **lumping/splitting**.

### 7a. Two roles a source can play

| | **Primary source** | **Comparison dataset** |
|---|---|---|
| examples | Stephan, Bush, Herculano-Houzel | DeCasien & Higham 2019 |
| public TSV in `__Public/comparative-data/` | yes | no |
| listed in a merge's `item_name` / `papers` | yes | no |
| has a spoke `species_key.csv` | yes | **yes** |
| resolved via `resolve_species()` | yes | **yes** |

Both roles use the **same resolver and the same spoke schema**. The only difference is that a
comparison dataset is resolved *for the comparison* and never written to a TSV or merged. So a
comparison join is always **accepted_name ↔ accepted_name**: resolve the benchmark's names to
`accepted_name`, resolve the merge's names to `accepted_name`, then compare — apples to apples.

**Give each comparison dataset its own spoke**, e.g. `_keys/DeCasien/species_key.csv`
(`collection = DeCasien`). Its variant rows live there, keyed by its own `source_publication`
(`DeCasien_Higham_2019`) — **not** dumped into another collection's key. (Today the proposed DeCasien
edits target `_keys/Stephan/species_key.csv`; under this design they move to the DeCasien spoke so
DeCasien names never leak into the Stephan collection's key.)

### 7b. Where the resolver stops: lumping vs spelling

The resolver maps a *name* to an `accepted_name`. It handles spelling variants and renames. It does
**not** decide that two *different* canonical names refer to the same animal — that is a taxonomic
judgement. The DeCasien comparison is full of exactly this: the benchmark carries full binomials
where our merge (mostly Stephan) carries genus-level `sp.`, and vice versa:

```
DeCasien "Ateles geoffroyi"  vs merge "Ateles sp"        value 72410 == 72410  (0% diff)
DeCasien "Tarsius sp"        vs merge "Tarsius syrichta"  value   133 ==   133
DeCasien "Avahi occidentalis" -> merge accepted "Avahi laniger"
```

These are **lumping/splitting** decisions, not spellings. The resolver will leave them as
non-matches until the equivalence is recorded in a key — and that is correct: lumping needs a human.

### 7c. The propose → review → key loop (keep it)

The existing DeCasien workflow is the right pattern and survives unchanged:

1. **Discover by value, name-agnostically.** Match benchmark cells to the merge by *value* within a
   genus and a tolerance (the process behind `DeCasien_vs_merge_comparison.csv`, status
   `match_taxonomy_variant`). This finds equivalences the keys don't know yet — keep it even after
   the resolver is in place, because the resolver makes joins *consistent* while value-match makes
   them *complete*.
2. **Propose, don't apply.** Candidate `variant → accepted` additions go to a review file
   (`DeCasien_taxonomy_proposed_changes.csv`) — never applied automatically.
3. **Human reviews and approves.**
4. **Record the decision in the spoke.** Approved equivalences become rows in the **DeCasien spoke**
   with the rationale in `note` (e.g. `note = "DeCasien splits; lumped to Stephan 'Ateles sp' on
   identical value 72410"`). From then on `resolve_species()` applies them automatically and
   identically in every comparison.

### 7d. Adjudication aids from the hub

Use `species_reference.csv` to settle hard cases: `ncbi_taxid` collapses synonyms/subspecies to one
ID, and `Order_resolved` / `Family_resolved` catch cross-rank mismatches. Optional future columns
worth considering: a `lumped_with` / `senior_synonym` field on the hub to make a lumping decision
first-class (rather than only implicit in spoke `note`s), so genuine splits-vs-lumps are queryable.

### 7e. Caveat — join granularity

`accepted_name ↔ accepted_name` joins cleanly **only when both datasets agree on the canonical
unit**. Where a benchmark genuinely *splits* a species we *lump* (or vice versa) and you choose not
to reconcile, compare at **genus level** or flag the row rather than forcing a 1:1 match. The
value-match safety net in 7c is what keeps those visible.

---

## 8. What does NOT change

- The hub-and-spoke structure and the rationale for per-collection files (`_keys/README.md`).
- `species_reference.csv` / `anatomy_reference.csv` shapes and `resolve_taxonomy.R`.
- The per-paper snapshot → CSV → public-TSV build (it just stops doing any species harmonisation).
- Anatomy/structure naming — this spec is species only; structures follow the parallel
  `anatomy_key.csv` → `anatomy_reference.csv` path and could get the same treatment later.
