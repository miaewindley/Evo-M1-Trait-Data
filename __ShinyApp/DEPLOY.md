# Evo-M1 Comparative Brain-Trait Data — Shiny app

A public web app to **search, filter, plot, and download** the comparative
brain-trait data compiled in this project.

## What it contains

- **Compiled database** — harmonized long tables across three datasets
  (brain-structure volumes, cell counts, and the EvoM1 trait table:
  dexterity / corticospinal tract, gyrification, interlaminar astrocytes,
  life-history & ecology): 13,531 non-missing values across 503 species and
  309 measurements. Filter by dataset, species, measurement, and source;
  download the current selection; scatter any two numeric variables
  (log-log with fit line).
- **Source tables** — 180 per-publication TSVs, each shown with its full
  citation and linked to its DOI / PubMed / ISBN / dissertation record
  (the identifier is the clickable link text), with source notes where
  available.
- **About tab** — dataset summary plus a CC BY 4.0 license and attribution
  notice.

## Files

```
__ShinyApp/
  app.R                     the whole app (single file)
  build_data.R              regenerates the two derived files + fallback copies
  data/                     <-- fallback cache only (do not hand-edit)
    evom1_traits_long.csv   DERIVED: melted from ____EvoM1_TraitTable/*.xlsx
    source_manifest.csv     DERIVED: source-table catalogue + citations
    volumes_long.csv        fallback copy of __merging_volumes/volumes_long.csv
    cellcounts_long.csv     fallback copy of __merging_cellcounts/cellcounts_long.csv
```

## Where the data comes from (GitHub, single source of truth)

At runtime the app reads its data over HTTP from the public GitHub repo
(`raw.githubusercontent.com/AleAliSousa/Evo-M1-Trait-Data/main/…`):

| Data | Fetched from (GitHub) |
|------|-----------------------|
| Brain-structure volumes | `__merging_volumes/volumes_long.csv` |
| Cell counts | `__merging_cellcounts/cellcounts_long.csv` |
| EvoM1 traits (derived) | `__ShinyApp/data/evom1_traits_long.csv` |
| Source-table catalogue (derived) | `__ShinyApp/data/source_manifest.csv` |
| The 180 source tables | `__Public/comparative-data/…` (fetched on demand) |

Because it reads the repo directly, **the 180 source tables are not duplicated
in the app at all**, and updating the data is just a `git push` — no redeploy
needed. If GitHub is briefly unreachable, the app falls back to the small local
copies in `data/` for the four startup files (the compiled database keeps
working; individual source-table views need the network).

Only two files are genuinely *derived* (the trait table is melted from `.xlsx`;
the manifest joins filenames to citations in `__ReadMe.xlsx`), so a small build
step is still needed. Regenerate them whenever the merge or trait tables change,
then commit and push:

```r
install.packages("readxl")            # one time
```
```bash
Rscript __ShinyApp/build_data.R
git add __ShinyApp/data/evom1_traits_long.csv __ShinyApp/data/source_manifest.csv \
        __ShinyApp/data/volumes_long.csv __ShinyApp/data/cellcounts_long.csv
git commit -m "Refresh Shiny app data" && git push
```

One-time cleanup (the old bundled copies of the 180 source tables are no longer
needed):

```bash
git rm -r __ShinyApp/data/source-tables && git commit -m "Drop duplicated source tables" && git push
```

> To point the app at a different branch or fork, set the `EVOM1_GH_BASE`
> environment variable (defaults to the `main` branch of this repo).

## Run locally

```r
install.packages(c("shiny", "bslib", "DT", "ggplot2"))
shiny::runApp("__ShinyApp")   # reads from GitHub; falls back to data/ if offline
```

## Deploy publicly to shinyapps.io

1. **Push first.** The deployed app reads data from GitHub, so make sure your
   latest data (and the two derived files) are committed and pushed to `main`.
2. Create a free account at https://www.shinyapps.io. In **Account → Tokens**,
   click **Show → Show secret → Copy to clipboard** to get the full
   `setAccountInfo(...)` command with real values, and run it once in R:

   ```r
   install.packages("rsconnect")
   rsconnect::setAccountInfo(name = "...", token = "...", secret = "...")
   ```

3. Deploy (run from the repo root, the folder that contains `__ShinyApp/`):

   ```r
   rsconnect::deployApp(
     appDir   = "__ShinyApp",
     appName  = "evo-m1-brain-traits",
     appTitle = "Evo-M1 Comparative Brain-Trait Data"
   )
   ```

   `rsconnect` scans `app.R`, installs shiny/bslib/DT/ggplot2 on the server,
   uploads the tiny `data/` fallback, and returns a public URL like
   `https://<your-account>.shinyapps.io/evo-m1-brain-traits/`.

To update later, re-run the same `deployApp(...)` call.

### Notes for shinyapps.io

- The free tier allows a limited number of active hours per month; the bundle
  here (~3 MB) is well within limits.
- No secrets or credentials are needed — all data is static and public.
- If you prefer an institutional server (Posit Connect / self-hosted Shiny
  Server), the same `__ShinyApp/` folder deploys there unchanged.
