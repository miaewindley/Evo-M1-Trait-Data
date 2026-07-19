## Compile the comparative SLEEP dataset (REM proportion + daily sleep duration).
## Pattern mirrors __merging_gyrification / __merging_cerebral_metabolic_rate: read each source's
## public TSV, relabel its columns via the stacked standardized-term map, stack to long, summarise
## to wide. One row per species per trait in long; one row per species in wide with a column per trait.
##
## Scope: SLEEP traits only.
##   REM_sleep_pct  = per cent of total sleep spent in REM        (unit: percent)
##   Sleep_h_day    = total daily sleep                            (unit: hours/day)
## Eagleman's non-sleep developmental columns (time-to-locomotion / weaning / adolescence) are NOT
## pulled here; Herculano-Houzel's neuron-density columns are NOT pulled here. See README.
##
## Sources / teams (this build):
##   Eagleman_2021       = Eagleman_Vaughn_2021_TABLE1   -> REM_sleep_pct  (25 primates)
##   HerculanoHouzel_2015= HerculanoHouzel__2015_Table1  -> Sleep_h_day    (24 mammals)
## The two teams contribute DIFFERENT traits, so no within-trait averaging or citation-dependency
## conflict arises yet. Combine rules (team-aware, citation-dependency-aware) are documented in the
## README and take effect when a second source of the SAME trait is added.
##
## Species key: Eagleman lists COMMON names -> resolved to accepted binomials via
## species_resolution_Eagleman.csv (each row carries a species_confidence flag; 'review' = verify).
## Herculano-Houzel lists binomials; only spelling is normalised (Loxodonta Africana -> africana).
##
## Outputs: sleep_long.csv, sleep_wide.csv, sleep_source_species_ids.csv
suppressWarnings(suppressMessages(library(tidyverse)))

.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
    return(normalizePath(rstudioapi::getActiveDocumentContext()$path))
  "."
})
setwd(dirname(.sp))
base   <- normalizePath(file.path(dirname(.sp), ".."))
tsvdir <- file.path(base, "__Public", "comparative-data")

item_name <- c("Eagleman_Vaughn_2021_TABLE1",
               "HerculanoHouzel__2015_Table1")
team_of   <- c(Eagleman_Vaughn_2021_TABLE1  = "Eagleman_2021",
               HerculanoHouzel__2015_Table1 = "HerculanoHouzel_2015")

terms <- readr::read_csv("standardized_term_sleep.csv", show_col_types = FALSE)
codes <- readxl::read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
enc   <- function(nm) codes$`Item encoded`[match(nm, codes$`Item name`)]

## Eagleman common-name -> binomial resolution (edit the CSV, not this script)
res <- readr::read_csv("species_resolution_Eagleman.csv", show_col_types = FALSE)
## Herculano-Houzel binomial spelling normalisation
hh_alias <- c("Loxodonta Africana" = "Loxodonta africana")
fix_hh <- function(s) ifelse(s %in% names(hh_alias), hh_alias[s], s)

## ---- long: one row per (Species, source, trait) ----------------------------
long <- list()

# Eagleman -> REM_sleep_pct
d <- readr::read_tsv(file.path(tsvdir, paste0(enc("Eagleman_Vaughn_2021_TABLE1"), ".tsv")),
                     show_col_types = FALSE)
d <- d |>
  rename(Species_printed = Species) |>
  left_join(res, by = c("Species_printed" = "Species_common")) |>
  mutate(Value = suppressWarnings(as.numeric(REM_sleep_percent))) |>
  filter(!is.na(Value)) |>
  transmute(Species,
            Species_printed,
            Standardized_Term = "REM_sleep_pct",
            Value, Units = "percent",
            source = "Eagleman_Vaughn_2021_TABLE1",
            team   = team_of[["Eagleman_Vaughn_2021_TABLE1"]],
            ref = "Table1",
            species_confidence,
            dependency_group = "REM_pct")
long[["eag"]] <- d

# Herculano-Houzel -> Sleep_h_day
d <- readr::read_tsv(file.path(tsvdir, paste0(enc("HerculanoHouzel__2015_Table1"), ".tsv")),
                     show_col_types = FALSE)
d <- d |>
  mutate(Species_printed = species,
         Species = fix_hh(species),
         Value = suppressWarnings(as.numeric(`daily.sleep..h.`))) |>
  filter(!is.na(Value)) |>
  transmute(Species, Species_printed,
            Standardized_Term = "Sleep_h_day",
            Value, Units = "hours/day",
            source = "HerculanoHouzel__2015_Table1",
            team   = team_of[["HerculanoHouzel__2015_Table1"]],
            ref = "Table1",
            species_confidence = "high",
            dependency_group = "dailysleep")
long[["hh"]] <- d

long <- bind_rows(long)
readr::write_csv(long, "sleep_long.csv")

readr::write_csv(
  long |> transmute(source, Species, Species_printed, Standardized_Term, Value, species_confidence),
  "sleep_source_species_ids.csv")

## ---- wide: one row per species, one column per trait ------------------------
rem <- long |> filter(Standardized_Term == "REM_sleep_pct") |>
  group_by(Species) |> summarise(REM_sleep_pct = first(Value),
                                 REM_species_confidence = first(species_confidence), .groups = "drop")
slp <- long |> filter(Standardized_Term == "Sleep_h_day") |>
  group_by(Species) |> summarise(Sleep_h_day = first(Value), .groups = "drop")

wide <- tibble(Species = sort(unique(long$Species))) |>
  left_join(rem, by = "Species") |>
  left_join(slp, by = "Species") |>
  mutate(source_REM_sleep_pct = ifelse(!is.na(REM_sleep_pct), "Eagleman_Vaughn_2021_TABLE1", NA),
         source_Sleep_h_day   = ifelse(!is.na(Sleep_h_day),   "HerculanoHouzel__2015_Table1", NA),
         n_traits = (!is.na(REM_sleep_pct)) + (!is.na(Sleep_h_day))) |>
  transmute(Species, REM_sleep_pct, Sleep_h_day,
            source_REM_sleep_pct, source_Sleep_h_day, n_traits, REM_species_confidence)
readr::write_csv(wide, "sleep_wide.csv")

message("sleep: ", nrow(long), " long rows (",
        sum(long$Standardized_Term == "REM_sleep_pct"), " REM, ",
        sum(long$Standardized_Term == "Sleep_h_day"), " daily-sleep), ",
        nrow(wide), " species (", sum(wide$n_traits == 2), " with both traits)")
