# Merging body & ecology data

Pipeline for compiling **whole-organism** traits — the body/ecology counterpart of
`__merging_volumes/`, `__merging_cellcounts/`, and `__merging_cerebral_metabolic_rate/`.
These are organism-level measures (body mass, body BMR, ecology / life-history), a different
family from the brain-structure merges, so they get their own merge.

**Measure classes.** The table is keyed by `measure_class` so classes are added incrementally:

| measure_class | status | Measure(s) |
|---|---|---|
| `mass` | **built** | `Body_Mass` (g) |
| `metabolic (body)` | planned | whole-body BMR (Genoud 2018, Isler 2008 BMR col, White & Seymour) — its own units |
| `life_history` | planned | longevity, gestation, weaning, litter size (Lewitus 2014, AnAge) |
| `diet_ecology` | planned | diet %s, trophic guild, foraging stratum, activity (Wilman 2014) |

## Body mass (first class)

Harvested from **39 source tables** that record body mass. Each source's species-level
body-mass column is auto-selected (`body_ecology_source_columns.csv` logs the choice + unit for
audit), values are converted to the project unit **grams** (kg×1000, mg×0.001; unit-less
columns verified as g by magnitude), and species are resolved to the accepted binomial via the
combined `_keys/*/species_key.csv` + `species_reference.csv`.

### Preventing duplication — three mechanisms

Body mass is the most re-reported variable in the project, so the merge defeats three distinct
duplication modes:

1. **Same-specimen re-reporting.** Papers from one collection re-print body masses for the
   *same animals* (e.g. Stephan 1970/1981, Frahm, Baron, Matano are all the **Stephan
   collection**). The merge **collapses within a team** first (team from
   `_keys/team_grouping_crosswalk.csv`; papers not in a known collection are their own team),
   so a collection counts once.
2. **Compilation double-counting.** Secondary tables reprint other people's numbers. Each row
   carries a `role` (primary = measured the animal; secondary = looked-up/compilation, from
   `_keys/variable_catalog.csv`). Pooling is **primary-preferred**: if any team measured the
   species, only primary team-values set the headline; secondaries fill species with no primary.
3. **Unit / name double-entry** (g vs kg vs mg, `Body_weight` vs `Body_Mass.g`). Converted to
   one unit here and, in the app, unified by `_keys/variable_canonical.csv`.

### Pooling

`Value` = mean of the primary team-values (or all team-values if no primary), after within-team
collapse. `Value_median` is the same pooled with the **median** — use it as the robust headline
when a species is flagged for disagreement (the mean is dragged by source errors; e.g. Wilman
lists *Lagothrix cana* as 6 g). Every species measured by >1 source is written to
`body_ecology_dedupe_report.csv` with the per-source values and a `DISAGREEMENT>2x` flag
(151 species) — these are for review; most are sexual dimorphism, captive-vs-wild, or genuine
source typos.

## Steps

1. **Compile** — `build_body_ecology_merge.py` (the tested builder that generated the shipped
   CSVs; R was unavailable in the build environment, same arrangement as the metabolic and
   Karbowski builds) **or** the house-style twin `body_ecology_compiled.R` (same logic).

## Outputs

- **`body_ecology_long.csv`** — one row per Species × Measure:
  `Species, measure_class, Measure, Units, Value, Value_median, n_sources, n_teams,
  n_teams_primary, primary_used, Teams, roles, value_min, value_max`. **5,576 species**
  for body mass (all-mammal, since Wilman/EltonTraits is included).
- **`body_ecology_wide.csv`** — Species × Measure (`Body_Mass.g` so far).
- **`body_ecology_unfiltered.csv`** — every harvested row with full provenance
  (Species, Species_raw, Value_g, raw_value, raw_unit, Source, first_author, Year, Team, role);
  10,403 rows.
- **`body_ecology_dedupe_report.csv`** — cross-source disagreements (review list).
- **`body_ecology_source_columns.csv`** — which column + unit was taken from each source (audit).

## Known limitations

- Sources that use **common names** (Burish 2010 "Rhesus macaque", a few Heffner/Weaver rows —
  31 rows total, 0.3%) don't resolve to a binomial and stay unmerged. A common-name→binomial
  map would recover them.
- The all-mammal scope means most of the 5,576 species have a single (Wilman) source; the
  merge's pooling value-add is for the ~300 species measured by multiple sources.

## App integration (next)

Add `__merging_body_ecology/body_ecology_long.csv` as a dataset in `__ShinyApp/app.R`
(`load_compiled`), and drop the now-redundant raw body-mass columns from the other three tables'
canonical pooling so `Body_Mass (g)` has a single authoritative source. Not yet wired.
