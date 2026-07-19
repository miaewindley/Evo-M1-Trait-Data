# Merging behaviour data

Assembles a comparative **behavioural** dataset across six measure classes — **vocal repertoire
size**, **digital dexterity**, **quadrupedal walking gait**, **locomotor diversity**, **hand
preference (handedness)**, and **manipulation complexity** — one row per species, following the
`standardized_term` + compile pattern of the other `__merging_*` folders.

## Why one folder for several traits

The single-measure merges (`__merging_volumes`, `__merging_gyrification`, …) each compile one
measure class. Behaviour groups several small behavioural traits that each have too few sources to
justify a folder of their own, while giving a single **cross-behaviour** table for correlation.
Per `__HOWTO_build_a_dataset_file.md` §10, different measure classes are **never pooled into one
value**: each keeps its own `Standardized_Term` and its own column. This folder only (a) dedups the
two classes that have more than one source, and (b) places the classes side by side per species.

It composes the project's harmonised trait tables in `____EvoM1_TraitTable/` (each itself built from
the sources' public TSVs by an `EvoM1_read_*.R`). The **species key mirrors
`__ShinyApp/build_data.R`**: use `species_sci` where present, else the paper's printed `Species`,
cleaned — so the merge species are identical to what the app correlates on. (This matters: the
dexterity table leaves `species_sci` blank on its corticospinal-tract-only rows, whose dexterity
ratings must still be kept via `Species`.)

## Domains, standardized terms, sources

| Domain | Standardized_Term(s) | source(s) | dedup | species |
|---|---|---|---|---|
| Vocalization | `VocalRepertoire` | Schniter 2026 (primary) + ManyPrimates 2022 | citation-dependent (McComb & Semple 2005) → prefer Schniter updated | 65 |
| Dexterity | `Dexterity` (Heffner & Masterton 1–7 scale) | Heffner & Masterton 1975 (primary) + Iwaniuk 1999 | citation-dependent → prefer Heffner & Masterton | 66 |
| Gait | `Duty_Factor`, `Phase`, `Gait`, `Foot_Posture` | Wimberly et al. 2021 | single source | 154 |
| Locomotion | `Locomotor_diversity_index`, `Intermembral_index`, `Arboreal_terrestrial` | Granatosky 2018 | single source | 113 |
| Handedness | `Handedness_index_mean`, `Handedness_strength_mean` | Caspar et al. 2022 | single source | 38 |
| Manipulation | `Manipulation_complexity`, `Tool_use`, `Extractive_foraging` | Heldstab et al. 2016 | single source | 37 |

### Dedup detail (the two multi-source classes)

- **Vocalization.** Both sources draw substantially on McComb & Semple 2005 (the ManyPrimates values
  mostly equal Schniter's MS2005 column). Citation-dependent → never averaged. Prefer Schniter's
  *updated* repertoire (most recent, per-species refs); use ManyPrimates only for species Schniter
  lacks. 65 species (42 Schniter + 23 ManyPrimates-only, 16 dependent overlaps).
- **Dexterity.** Iwaniuk et al. 1999 is explicitly *"a re-analysis of the Heffner and Masterton
  (1975) data"* — same 1–7 scale, **identical values on all 24 shared species**. Citation-dependent
  → prefer Heffner & Masterton (the origin of the scale). 66 species (65 Heffner + 1 Iwaniuk-only).

The other four domains are single-source (nothing to dedup); `Gait`/`Foot_Posture` and
`Arboreal_terrestrial` are categorical, the rest continuous or ordinal.

## Coverage

**318 species** total. Distribution by number of behavioural domains present: 222 species in 1
domain, 62 in 2, 18 in 3, 9 in 4, 5 in 5, and **2 in all six** (*Pan troglodytes*, *Sapajus apella*).

## Outputs

- **`behaviour_long.csv`** — one row per (Species, source, Standardized_Term) observation
  (1,245 rows). Columns: `Species, Domain, Standardized_Term, Value, source, team, dependency_group`.
- **`behaviour_wide.csv`** — one row per species (318). Merged value per multi-source class plus
  `*_source` / `*_citation_dependency` flags, the single-source term columns, and `n_domains`.
- **`behaviour_source_species_ids.csv`** — provenance: which source contributed each value.
- **`standardized_term_behaviour.csv`** (+ `standardized_term.R`, `standardized_term_by_reference/`)
  — the original→standardized column map, stacked per source (8 sources).

The compile also writes **`____EvoM1_TraitTable/behaviour_merged.xlsx`** — the single behavioural
trait table the Shiny app reads, with per-cell `_Source` attribution for every domain.

## Rebuild

Run `behaviour_compiled.R` (reads the harmonised `____EvoM1_TraitTable/*.xlsx`; rebuild a source
trait table first if its snapshot/CSV changed). `standardized_term.R` restacks the term map if a
per-reference term file changes. Then re-run `__ShinyApp/build_data.R`.

## Notes / future
- **Not included:** brain-volume laterality/asymmetry (that is a volume measure in
  `__merging_volumes`, not a behavioural trait), and Eagleman's developmental time-to-locomotion
  (a life-history column excluded from `__merging_sleep`, unrelated to locomotor diversity here).
- To add a future behavioural source, drop a `<Reference>_standardized_terms.csv` in
  `standardized_term_by_reference/`, add a `melt_tab(...)` call in `behaviour_compiled.R` (with its
  team + dependency group), and — if it shares a measure class with an existing source — decide the
  dedup/dependency rule.
