# Handling wide-coverage traits & taxonomic growth (backbone vs specialist)

Design note for the concern: *some variables (body mass, body BMR, brain size, base
ecological vars) exist for LOADS of species — potentially beyond mammals — while the
core M1/brain traits are deep-but-narrow. How do we handle this, especially in the
Shiny app, so the dataset can grow into non-mammals later?*

---

## What the repo already does right

- **Storage is long, not wide.** `compiled` in `__ShinyApp/app.R` is a union of three
  long tables (`volumes_long.csv`, `cellcounts_long.csv`, `evom1_traits_long.csv`) in
  `Species × Variable × Value × Source` shape. Ragged coverage costs nothing here — a
  species with only body mass just has fewer rows. This is the right foundation; keep it.
- **Concept-pooling already exists.** `_keys/variable_canonical.csv` pools duplicated
  backbone variables into one house concept + unit with conversion factors — e.g.
  `Body_Mass.g`, `Body_weight`, `Body weight kg` → **Body_Mass (g)**; three `Brain_Mass`
  variants → **Brain_Mass (g)**. It even has a `concept` column already.
- **The plot handles ragged coverage.** `p_data()` does a `complete.cases` intersection,
  so X-vs-Y only plots species with both variables. No NA explosion at plot time.
- **A taxonomy backbone exists in `_keys`.** `species_reference.csv` carries
  `Order_resolved`, `Family_resolved`, `ncbi_taxid`, per-source membership flags, and a
  `taxonomy_source`; `resolve_taxonomy.R` resolves via NCBI + MDD.

## The four real gaps

1. **The taxonomy backbone is mammal-only and isn't wired into the app.**
   `species_reference.csv` has **no `Class` column** (everything is implicitly Mammalia;
   only Order/Family), and `resolve_taxonomy.R` resolves against **MDD = Mammal Diversity
   Database**, which will silently drop any non-mammal. The app never reads
   `species_reference.csv` at all — `sp_choices` is just the flat unique species list.
2. **Backbone traits are physically duplicated across merges.** Body/brain mass is stored
   independently in every merge:
   - `Body_Mass.g`: volumes_long **99**, cellcounts_long **80**, traits **102**
   - `Brain_Mass`: volumes **97**, cellcounts **70**, traits **154**
   Pooling papers over this at display time, but re-deriving the same value in each merge
   is where drift enters — already flagged (the `Brain_Mass.mg` audit rows / mg-vs-g
   mislabel note in `variable_canonical.csv`).
3. **No taxonomic filter axis in the app.** Species and variables are the only filters, so
   you can't say "mammals only" or "primates only" independent of trait choice.
4. **Only body & brain mass are pooled.** BMR (`metabolic_rate`, present in the trait
   table and in `__merging_cerebral_metabolic_rate`) and diet/ecology aren't in
   `variable_canonical.csv` yet, so they don't pool and won't carry a scope tag.

---

## Concrete changes

### 1. Give traits a taxonomic *scope*, and give species a *Class* — two independent axes

The core fix is to stop letting taxonomic scope and trait scope move together.

**a. Extend `_keys/variable_canonical.csv` into the single trait catalogue.** Add two
columns beside the existing `concept`:

| new column | values | purpose |
|---|---|---|
| `trait_scope` | `pan-vertebrate` / `mammal-wide` / `primate-core` | declares how far a trait legitimately extends |
| `role` | `backbone` / `specialist` | backbone = wide-coverage reference traits |

Mark `Body_Mass`, `Brain_Mass`, `BMR`, diet, activity-period as `role=backbone,
trait_scope=pan-vertebrate`; nuclei volumes, cortical areas, gyrification, CST, ILAs as
`role=specialist, trait_scope=primate-core` (or `mammal-wide`). This is a metadata-only
change — no data moves.

**b. Add `Class` (and optionally a higher `Clade`) to `species_reference.csv`.**
`Order_resolved` is already there; a `Class` column is what lets the app filter Mammalia
vs non-mammals. Backfill existing rows to `Mammalia`.

**c. Fix the resolver before any non-mammal is added.** `resolve_taxonomy.R` is
MDD-gated; add a non-mammal path (NCBI is already wired; GBIF backbone is the usual
choice) selected by `Class`, so adding a bird doesn't fail taxonomy resolution silently.

### 2. Wire the backbone into the app (mirrors how `variable_canonical` is already loaded)

- In `build_data.R`, copy `_keys/species_reference.csv` into `data/` (exactly like the
  existing `variable_canonical.csv` fallback copy at lines 37–39).
- In `app.R load_compiled()`, left-join `compiled` to it on `Species` to attach
  `Class / Order_resolved / Family_resolved`, and join the trait catalogue to attach
  `role / trait_scope` per variable.
- Add a **taxonomic filter** (Class → Order → Family) as a *separate* sidebar control from
  the variable filter.
- Make the variable dropdown **availability-driven**: once species/taxa are chosen,
  restrict variable choices to those with data for the selection, and show a coverage
  badge (n species per variable) so users see `Body_Mass` = thousands vs a nucleus = tens.
  The plot already intersects; extend the same "who actually has this" logic to the UI.

Result: pan-vertebrate body-mass-vs-brain-size shows thousands of species; primate nuclei
show the deep-but-narrow set — same app, no schema change.

### 3. Decide backbone storage: pool-at-display (now) vs one backbone merge (for growth)

- **Option A — keep per-merge duplication, rely on pooling.** Zero new infrastructure,
  works today. Cost: every new merge re-derives body/brain mass; drift risk is real and
  already showing (the mg/g audit rows).
- **Option B — extract one `__backbone_traits` merge (recommended for growth).** A single
  authoritative, team-aware, pan-taxonomic long table for `Body_Mass`, `Brain_Mass`, adult
  `BMR`, diet, activity. Other merges *reference* it instead of re-storing. Point the
  backbone concepts in `variable_canonical.csv` at it (`match_dataset = "Backbone"`). This
  is the natural entry point for non-mammals and kills the whole class of re-derivation
  bugs. Also finish pooling BMR + diet into the canonical map while doing this.

### 4. What "add non-mammals later" then looks like

Purely additive: append rows to the backbone long table + rows to `species_reference.csv`
(with `Class`). Nothing in the specialist merges changes — they stay absent for those
species, and the app's availability logic simply doesn't offer them when non-mammals are
in scope. No sparse wide matrix is ever materialised.

---

## Do-first checklist

1. Add `Class` to `species_reference.csv`; backfill `Mammalia`.
2. Add `role` + `trait_scope` to `variable_canonical.csv`; tag backbone vs specialist;
   add the missing BMR + diet concepts.
3. Join both into the app; add the taxonomic filter + availability-driven variable list.
4. De-MDD the resolver (add a `Class`-gated non-mammal path) **before** ingesting any
   non-mammal.
5. (When ready) extract `__backbone_traits` as the single authoritative wide-coverage
   source; repoint the canonical map at it.

Steps 1–3 are metadata + app wiring (low risk, high payoff). Step 5 is the larger
refactor and can wait until you actually add the first non-mammal.
