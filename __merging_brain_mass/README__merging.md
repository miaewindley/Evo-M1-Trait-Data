# Merging brain-mass data

Pipeline for compiling **whole-brain mass** across species — a sibling of the body-mass merge
(`__merging_body_ecology/`) and structured like `__merging_cerebral_metabolic_rate/`. Brain mass
is a brain measure (not organism/ecology), so it lives in its own merge rather than in
`body_ecology`.

Harvested from the **27 source tables** that record a whole-brain mass (of 29 with a brain-mass
column; 2 — MacLeod's `brainweight_known` — are non-numeric text). **Burger et al. 2019 SD1
(1,552 species)** is by far the largest contributor.

## Preventing duplication
Same three mechanisms as the body-mass merge:

1. **Same-specimen re-reporting** → collapse within a team first (team from
   `_keys/team_grouping_crosswalk.csv`; e.g. the Stephan collection's brain weights, reported
   across Stephan 1970/1981 and the Karger tables, count once).
2. **Compilation double-counting** → `role` from `_keys/variable_catalog.csv` (primary = measured
   the brain, secondary = compilation such as Burger/Lewitus); pooling is primary-preferred.
3. **Unit double-entry** → all converted to grams. Units come from the column name where present
   (`_mg`, `(g)`, `kg`, `cm3`); for **unit-less** columns the unit is inferred by magnitude —
   mammal brains are < ~10,000 g, so a column whose max exceeds 20,000 is milligrams. Crucially
   the magnitude is pooled **per (author, column) across all of an author's tables**, not per
   file: Stephan's unit-less `Brain_weight` is mg, and this is decided from the whole Stephan set
   (max ≈ 1.33 M) so a small-taxa subtable (e.g. Table I, all insectivores, max < 20,000) is not
   mislabelled grams. `1 cm³ = 1 g` is assumed where a source reported volume (Burger's convention).

No double-counting against `__merging_volumes`: this harvest reads the **source TSVs**, which are
the same primaries the volumes merge derives its `Brain_Mass.mg` from — so brain mass is compiled
once, here, with much wider coverage (1,616 vs 97 species).

## Pooling
`Value` = mean of primary team-values (or all team-values if no primary), after within-team
collapse; `Value_median` is the robust alternative for flagged species. Every species measured by
>1 source is in `brain_mass_dedupe_report.csv` with a `DISAGREEMENT>2x` flag (only **7**, all
normal measurement variation after the unit fix).

## Outputs
- **`brain_mass_long.csv`** — one row per species: `Species, measure_class, Measure, Units, Value,
  Value_median, n_sources, n_teams, n_teams_primary, primary_used, Teams, roles, value_min,
  value_max`. **1,616 species.**
- **`brain_mass_wide.csv`** — Species × `Brain_Mass.g`.
- **`brain_mass_unfiltered.csv`** — every harvested row with provenance (2,308 rows).
- **`brain_mass_dedupe_report.csv`** — cross-source disagreements (review list).
- **`brain_mass_source_columns.csv`** — chosen column + resolved unit per source (audit).

## Build
`build_brain_mass_merge.py` is the tested builder (no R in the build env); `brain_mass_compiled.R`
is the house twin (identical logic). Re-run after any source TSV changes.

## Verified
Homo 1,333 g, Gorilla 446 g, Macaca mulatta 94 g, Microcebus murinus 1.78 g, Sorex minutus
0.11 g, Loxodonta africana ~4,900 g — all correct. Burger contributes 1,551 rows (secondary).

## Known limitations
- MacLeod 2000/2003 (`brainweight_known`, s0047-2484) is non-numeric text and contributes nothing
  yet; would need parsing.
- A few source rows use trinomials/subspecies (e.g. `Homo sapiens sapiens`, `Papio cynocephalus
  anubis`) that don't collapse to the binomial — add key rows if a specific species needs merging.
