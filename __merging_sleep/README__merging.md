# Merging sleep data

Compiles a comparative dataset of **sleep traits** across papers, following the same
`standardized_term` + compile pattern as `__merging_volumes`, `__merging_gyrification`, and
`__merging_cerebral_metabolic_rate`. Built as a standing home for sleep/REM data because **more
sources are expected** — the structure is designed to grow (see *Adding a source* below).

## Scope: sleep traits only

| Standardized_Term | meaning | unit |
|---|---|---|
| `Species` | accepted binomial (join key) | — |
| `REM_sleep_pct` | per cent of total sleep spent in REM | percent |
| `Sleep_h_day` | total daily sleep | hours/day |

**Deliberately excluded from this merge (kept in their source folders):**
- Eagleman's non-sleep developmental columns — `Time_to_locomotion_days`, `Time_to_weaning_days`,
  `Time_to_adolescence_months`, `Phylogenetic_distance_Mya`.
- Herculano-Houzel's neuron-density / brain-mass columns (those belong with cellcount / volume merges).
- `HerculanoHouzel__2015_Table2` — an **age series** ("Asleep %" by age), not cross-species; useful
  only for developmental context.

## Sources (this build)

| Reference | team | trait | species | role |
|---|---|---|---|---|
| `Eagleman_Vaughn_2021_TABLE1` | Eagleman_2021 | `REM_sleep_pct` | 25 (all primates) | **primary** for REM proportion |
| `HerculanoHouzel__2015_Table1` | HerculanoHouzel_2015 | `Sleep_h_day` | 24 (mammals) | **primary** for daily sleep duration |

Both source values are themselves literature compilations (secondary). Herculano-Houzel's daily-sleep
column derives largely from the mammalian-sleep compilations (e.g. Savage & West 2007) — relevant for
the citation-dependency rule once a second daily-sleep source is added.

## Team-aware, citation-dependency-aware combine

Same rules as the blood-flow / volume / gyrification merges. **They do not bite yet** because the two
current sources contribute *different* traits, so no two values ever compete. The rules are stated here
so the next contributor applies them:

- **Within a team (same paper), newest/authoritative wins.**
- **Across teams, average — UNLESS the sources are citation-dependent** (one compiled from the other,
  or both from a shared upstream compilation). Citation-dependent sources are **never averaged**;
  prefer the primary and keep the other value alongside, flagged.

## Species key & resolution

- **Eagleman lists common names** ("Spider monkey", "Rhesus monkey", …). These are resolved to accepted
  binomials in **`species_resolution_Eagleman.csv`**, which carries a `species_confidence` flag:
  - `high` — unambiguous (e.g. Rhesus monkey → *Macaca mulatta*).
  - `medium` — standard-by-convention within a species group (Vervet → *Chlorocebus pygerythrus*;
    Green monkey → *Chlorocebus sabaeus*; both in the *aethiops* group).
  - `review` — **genuinely ambiguous, verify**: *Spider monkey* → *Ateles geoffroyi* (genus only in
    source) and *Brown lemur* → *Eulemur fulvus* (the *fulvus* complex). Edit the CSV to correct.
- **Herculano-Houzel lists binomials**; only the printed typo `Loxodonta Africana` → `Loxodonta africana`
  is normalised. Genus-level labels (`Callithrix sp.`, `Dendrohyrax sp.`, `Procavia sp.`, `Tupaia sp.`)
  are kept as-is and will **not** join to a species-level row (e.g. HH `Callithrix sp.` ≠ Eagleman
  *Callithrix jacchus*).

## Outputs

- **`sleep_long.csv`** — one row per (Species, source, trait) observation (49 rows). Columns:
  `Species, Species_printed, Standardized_Term, Value, Units, source, team, ref, species_confidence,
  dependency_group`.
- **`sleep_wide.csv`** — one row per species (43). Columns: `Species, REM_sleep_pct, Sleep_h_day,
  source_REM_sleep_pct, source_Sleep_h_day, n_traits, REM_species_confidence`. **6 species carry both
  traits**: *Aotus trivirgatus, Homo sapiens, Macaca mulatta, Macaca radiata, Papio cynocephalus,
  Saimiri sciureus*.
- **`sleep_source_species_ids.csv`** — provenance: which source contributed each species value.
- **`species_resolution_Eagleman.csv`** — the editable common→binomial map with confidence flags.
- **`standardized_term_sleep.csv`** (+ `standardized_term.R`, `standardized_term_by_reference/`) — the
  original→standardized column map, stacked per source.

## Rebuild

Run **`sleep_compiled.R`** (reads the sources' public TSVs from `__Public/comparative-data/`;
regenerate a source TSV first if its snapshot/CSV changed). `standardized_term.R` restacks the term map
if a per-reference term file changes.

> Note: the CSV outputs in this folder were generated with a Python port of `sleep_compiled.R`
> (`build_sleep_merge.py`) because R was unavailable at build time. Re-running `sleep_compiled.R` in R
> reproduces them identically; R remains the canonical path.

## Adding a source (the "more is coming" path)

1. Make sure the new table is built to house convention in its own folder and has a harmonized TSV in
   `__Public/comparative-data/` with a row in `__ReadMe.xlsx` (`Item name` / `Item encoded`).
2. Drop a `<Reference>_standardized_terms.csv` in `standardized_term_by_reference/` mapping its columns
   to `REM_sleep_pct` / `Sleep_h_day` (or a **new** sleep term — add it to the Scope table above and
   give it a `Units`).
3. Add the `Item name` to `item_name` in `sleep_compiled.R`, set its `team`, and, **if it shares a trait
   with an existing source**, decide the combine rule (average vs citation-dependent → prefer primary).
4. If its species are common names or non-standard, extend `species_resolution_Eagleman.csv` (or add a
   parallel resolution file) with confidence flags.
5. Re-run `standardized_term.R` then `sleep_compiled.R`.

## Feeding the Shiny app  ✅ wired

This merge is surfaced in the trait explorer. The chain:

1. **`____EvoM1_TraitTable/EvoM1_read_sleep.R`** reads `sleep_wide.csv` and writes
   `____EvoM1_TraitTable/sleep.xlsx` (columns `species_sci, Species, REM_sleep_pct,
   REM_sleep_pct_Source, Sleep_h_day, Sleep_h_day_Source`; the per-cell `*_Source` columns credit each
   value to its own paper).
2. **`__ShinyApp/build_data.R`** has `sleep.xlsx` registered in `trait_files`, so it melts into
   `__ShinyApp/data/evom1_traits_long.csv` as variables `REM_sleep_pct` and `Sleep_h_day`
   (Dataset = "EvoM1 traits"). The app picks up new variables automatically.

Rebuild after changing the merge: run `EvoM1_read_sleep.R`, then `Rscript __ShinyApp/build_data.R`,
then commit + push (the deployed app fetches `evom1_traits_long.csv` from GitHub; a local run uses the
committed fallback). The 49 sleep rows are already in the committed `evom1_traits_long.csv`.

> The `sleep.xlsx` and the appended `evom1_traits_long.csv` rows were generated without R (unavailable
> at build time) and exactly match what `EvoM1_read_sleep.R` + `build_data.R` produce, so re-running
> those in R is idempotent.
