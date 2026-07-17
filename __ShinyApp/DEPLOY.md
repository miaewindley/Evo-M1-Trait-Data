# Evo-M1 Comparative Brain-Trait Data — Shiny app

A public web app to **search, filter, plot, and download** the comparative
brain-trait data compiled in this project.

## What it contains

- **Compiled database** — harmonized long tables (brain-structure volumes +
  cell counts): 9,681 non-missing values across 336 species and 239
  measurements. Filter by dataset, species, measurement, and source; download
  the current selection; scatter any two variables (log-log with fit line).
- **Source tables** — 157 per-publication TSVs, each linked to its DOI /
  PubMed / ISBN / dissertation record, with source notes where available.

## Files

```
__ShinyApp/
  app.R                     the whole app (single file)
  data/
    volumes_long.csv        bundled copy of __merging_volumes/volumes_long.csv
    cellcounts_long.csv     bundled copy of __merging_cellcounts/cellcounts_long.csv
    source_manifest.csv     catalogue of source tables (auto-generated)
    source-tables/          the 157 TSVs + source-note .md files
```

The data is **bundled** (copied into `data/`) so the app is fully
self-contained and portable. When the underlying merge is regenerated, refresh
the bundle by re-copying `volumes_long.csv` and `cellcounts_long.csv` and
rebuilding `source_manifest.csv`.

## Run locally

```r
install.packages(c("shiny", "bslib", "DT", "ggplot2"))
shiny::runApp("__ShinyApp")
```

## Deploy publicly to shinyapps.io

1. Create a free account at https://www.shinyapps.io and copy your token
   (Account → Tokens → Show).
2. In R, one time:

   ```r
   install.packages("rsconnect")
   rsconnect::setAccountInfo(name   = "<your-account>",
                             token  = "<token>",
                             secret = "<secret>")
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
   uploads `data/`, and returns a public URL like
   `https://<your-account>.shinyapps.io/evo-m1-brain-traits/`.

To update later, re-run the same `deployApp(...)` call.

### Notes for shinyapps.io

- The free tier allows a limited number of active hours per month; the bundle
  here (~3 MB) is well within limits.
- No secrets or credentials are needed — all data is static and public.
- If you prefer an institutional server (Posit Connect / self-hosted Shiny
  Server), the same `__ShinyApp/` folder deploys there unchanged.
