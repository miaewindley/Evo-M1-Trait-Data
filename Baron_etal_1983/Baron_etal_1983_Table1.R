# Baron_etal_1983_Table1.R
#
# Purpose
#   Convert the faithful Excel snapshot of Baron et al. 1983 Table 1 into an
#   analysis-ready CSV: numeric value columns, note markers split into their
#   own columns, meaningful column names, taxonomic grouping carried down from
#   the section headings, and updated species binomials taken from
#   Baron_1983.csv (matched by Baron code).
#
# Inputs
#   Baron_etal_1983_Table1_snapshot.xlsx   sheet: Table1_snapshot
#   Baron_1983.csv                         crosswalk for updated species names
#
# Output
#   Baron_etal_1983_Table1.csv             one row per species (76 rows)
#
# Notes
#   Values come from the snapshot, never from the CSV. The CSV is used only as
#   a name crosswalk (by code). The crosswalk is read with latin1 so the stray
#   non-UTF-8 byte in "Scutisorex somereni" cannot silently truncate it.

suppressPackageStartupMessages({
  library(readxl)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(tibble)
})

snapshot_file  <- "Baron_etal_1983_Table1_snapshot.xlsx"
snapshot_sheet <- "Table1_snapshot"
crosswalk_file <- "Baron_1983.csv"
output_file    <- "Baron_etal_1983_Table1.csv"

# ---- helpers ---------------------------------------------------------------

read_snapshot <- function(path, sheet) {
  raw <- read_excel(path, sheet = sheet, col_names = FALSE,
                    col_types = "text", na = c(""))
  header <- as.character(unlist(raw[2, ], use.names = FALSE))
  dat <- raw[-c(1, 2), , drop = FALSE]
  names(dat) <- header
  dat
}

read_baron_csv <- function(path) {
  read_csv(path,
           locale    = locale(encoding = "latin1"),
           col_types = cols(.default = col_character()),
           na        = c(""))
}

norm_code   <- function(x) suppressWarnings(as.integer(str_remove_all(as.character(x), "\\D")))
parse_value <- function(x) parse_number(x, na = c("", "-", "NA", "n.a.", "__"))

# Species label with the trailing Baron footnote digit removed.
clean_species  <- function(x) str_squish(str_remove_all(x, "[0-9]+"))
# The trailing footnote digit itself (e.g. "Erinaceus algirus1" -> "1"), else NA.
footnote_num   <- function(x) str_match(x, "([0-9]+)\\s*$")[, 2]
has_marker     <- function(x, marker) str_detect(replace_na(x, ""), fixed(marker))

# Section heading -> (Major_group, Subgroup). Headings in the printed table do
# not state their rank, so this small lookup encodes the paper's hierarchy:
# Basal/Progressive Insectivora sit under Insectivora; Prosimians/Simians sit
# under Primates; Scandentia and Macroscelidea stand alone.
group_lookup <- tribble(
  ~section,                  ~Major_group,    ~Subgroup,
  "Basal Insectivora",       "Insectivora",   "Basal Insectivora",
  "Progressive Insectivora", "Insectivora",   "Progressive Insectivora",
  "Scandentia",              "Scandentia",    NA_character_,
  "Primates",                "Primates",      NA_character_,
  "Prosimians",              "Primates",      "Prosimians",
  "Simians",                 "Primates",      "Simians",
  "Macroscelidea",           "Macroscelidea", NA_character_
)

# ---- read snapshot, carry section heading down, keep species rows ----------

snapshot_raw <- read_snapshot(snapshot_file, snapshot_sheet)

snap <- snapshot_raw %>%
  rename(code_raw = `code number of species`, species_raw = `species name`) %>%
  mutate(
    is_species = !is.na(code_raw) & str_detect(code_raw, "^[0-9]{4}$"),
    # Heading rows have no code, a label, and are not the "Means" block.
    is_heading = (is.na(code_raw) | code_raw == "") &
                 !is.na(species_raw) & species_raw != "Means",
    section    = if_else(is_heading, species_raw, NA_character_)
  ) %>%
  fill(section, .direction = "down") %>%
  filter(is_species) %>%
  left_join(group_lookup, by = "section") %>%
  mutate(Major_group = coalesce(Major_group, section))

# ---- updated binomials from Baron_1983.csv (matched by code) ---------------

updated_name <- rep(NA_character_, nrow(snap))

if (file.exists(crosswalk_file)) {
  crosswalk <- read_baron_csv(crosswalk_file) %>%
    filter(!str_detect(replace_na(Species, ""), "^AAAA_"),
           !is.na(code_Baron1983)) %>%
    transmute(code_join = norm_code(code_Baron1983), Species_updated = Species)
  updated_name <- crosswalk$Species_updated[match(norm_code(snap$code_raw),
                                                  crosswalk$code_join)]
} else {
  warning("Crosswalk '", crosswalk_file, "' not found; keeping original names.")
}
snap$Species_updated <- updated_name

# ---- assemble the analysis-ready table -------------------------------------

final.dataframe <- snap %>%
  transmute(
    Reference          = "Baron_etal_1983",
    Source_table       = "Table 1",
    Anatomy_code       = "MOB",
    Anatomy            = "main olfactory bulb",
    Structure_original = "total MOB (layers 1-6 + periventricular zone)",
    code_Baron1983     = code_raw,
    Major_group,
    Subgroup,
    Species                    = coalesce(Species_updated, clean_species(species_raw)),
    Species_Baron1983          = clean_species(species_raw),
    Species_Baron1983_footnote = footnote_num(species_raw),
    Number_of_individuals_Bulbus_olfactorius = as.integer(parse_value(n)),
    Number_of_individuals_note = if_else(has_marker(n, "*"), "*", NA_character_),
    Bulbus_olfactorius_1983    = parse_value(`volume in mm3`),
    Bulbus_olfactorius_note    = if_else(has_marker(`volume in mm3`, "+"), "+", NA_character_),
    Bulbus_olfactorius_SEM_percent_1983             = parse_value(`SEM in %`),
    Bulbus_olfactorius_size_index_1983              = parse_value(`size index`),
    Bulbus_olfactorius_per_mille_net_brain_1983     = parse_value(`MOB in %0 of net brain`),
    Bulbus_olfactorius_per_mille_telencephalon_1983 = parse_value(`MOB in %0 of telencephalon`),
    unit_volume        = "mm3",
    unit_SEM           = "percent",
    unit_per_mille     = "per mille"
  )

options(scipen = 999)
write_csv(final.dataframe, output_file)

message("Wrote ", output_file)
message("Rows in analysis table: ", nrow(final.dataframe))
message("Species with updated binomial from crosswalk: ",
        sum(!is.na(updated_name)))
