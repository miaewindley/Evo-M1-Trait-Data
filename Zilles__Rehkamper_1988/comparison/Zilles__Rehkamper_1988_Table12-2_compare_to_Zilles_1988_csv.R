# Zilles__Rehkamper_1988_Table12-2_compare_to_Zilles_1988_csv.R
#
# Checking step (self-contained in comparison/). Audit the journal-faithful
# snapshot of Zilles & Rehkamper (1988) Table 12-2 against Zilles_1988.csv.
#
# This table is structure-as-rows for a SINGLE species (Pongo sp.), so the audit
# is per-structure for that one species (rather than per-species): each snapshot
# structure volume (converted cc3 -> mm3) is matched to the corresponding column
# of the Pongo row in Zilles_1988.csv and compared. Structures printed in the
# table but not carried as their own canonical column in the CSV are reported as
# snapshot_only; CSV columns with a Pongo value but no row in Table 12-2 (body /
# brain weight from the chapter text, and the canonical Lobus_piriformis recode)
# are reported as csv_only -- both expected, not transcription errors.
#
# Inputs : ../Zilles__Rehkamper_1988_Table12-2_snapshot.xlsx (sheet Table12-2) ; Zilles_1988.csv
# Outputs: Zilles__Rehkamper_1988_Table12-2_comparison_report_from_R.csv
#          Zilles__Rehkamper_1988_Table12-2_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

snapshot_file     <- "../Zilles__Rehkamper_1988_Table12-2_snapshot.xlsx"
snapshot_sheet    <- "Table12-2"
comparison_file   <- "Zilles_1988.csv"
output_detail     <- "Zilles__Rehkamper_1988_Table12-2_comparison_report_from_R.csv"
output_mismatches <- "Zilles__Rehkamper_1988_Table12-2_comparison_mismatches_from_R.csv"
header_rows       <- 2L
species_in_csv    <- "Pongo sp."

parse_value <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
sup_class   <- "[¹²³⁴⁵⁶⁷⁸⁹⁰]"

# snapshot structure label -> Zilles_1988.csv column (shared, measured structures)
struct_to_col <- c(
  "Medulla oblongata"         = "Medulla_oblongata",
  "Cerebellum (without pons)" = "Cerebellum",
  "Mesencephalon"             = "Mesencephalon",
  "Diencephalon"              = "Diencephalon",
  "Telencephalon"             = "Telencephalon",
  "Neocortex"                 = "Neocortex",
  "Hippocampus"               = "Hippocampus",
  "Septum"                    = "Septum",
  "Corpus striatum"           = "Striatum",
  "Globus pallidus"           = "Pallidum",
  "Corpus amygdaloideum"      = "Amygdala",
  "Paleocortex"               = "Palaeocortex")

# --- snapshot side: structures + volume (cc3 -> mm3) ---
pos <- c("structure_disp","fresh_volume_cc3","pct_total_brain")
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
sdat <- raw %>% slice(-(seq_len(header_rows)))
names(sdat)[seq_along(pos)] <- pos
snap <- sdat %>%
  filter(!is.na(structure_disp), !is.na(parse_value(fresh_volume_cc3))) %>%
  transmute(structure = str_squish(str_remove_all(structure_disp, sup_class)),
            volume_mm3_snap = parse_value(fresh_volume_cc3) * 1000)

# --- csv side: the single Pongo row ---
comp <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!str_starts(replace_na(Species, ""), "AAAA_"), str_squish(Species) == species_in_csv)
pongo <- comp[1, ]
get_csv <- function(col) if (col %in% names(pongo)) parse_value(pongo[[col]]) else NA_real_

num_match <- function(a, b, tol = 1e-3) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)

# matched + snapshot-only
snap$csv_column <- unname(struct_to_col[snap$structure])
snap$value_csv  <- vapply(snap$csv_column, function(c) if (is.na(c)) NA_real_ else get_csv(c), numeric(1))
snap$status     <- ifelse(is.na(snap$csv_column), "snapshot_only_not_in_csv",
                    ifelse(num_match(snap$volume_mm3_snap, snap$value_csv), "matched", "MISMATCH"))

# csv-only: Pongo's OWN data columns (not _current / _source / id columns) with a value, not already matched
own_cols <- setdiff(names(comp), "Species")
own_cols <- own_cols[!str_detect(own_cols, "_current$|_source$") &
                     !str_detect(own_cols, "^(Species_|Number_|Code_)")]
mapped   <- unname(struct_to_col)
csv_only <- tibble(structure = character(), status = character(),
                   volume_mm3_snap = numeric(), value_csv = numeric(), csv_column = character())
for (cc in own_cols) {
  v <- get_csv(cc)
  if (!is.na(v) && !(cc %in% mapped))
    csv_only <- add_row(csv_only, structure = cc, status = "csv_only_not_in_snapshot",
                        volume_mm3_snap = NA_real_, value_csv = v, csv_column = cc)
}

report <- bind_rows(
  snap %>% transmute(structure, status, volume_mm3_snap, value_csv, csv_column),
  csv_only)

write_csv(report, output_detail)
write_csv(filter(report, status != "matched"), output_mismatches)
message("species: ", species_in_csv,
        " | matched structures: ", sum(report$status == "matched"),
        " | value mismatches: ",  sum(report$status == "MISMATCH"),
        " | snapshot-only: ",     sum(report$status == "snapshot_only_not_in_csv"),
        " | csv-only: ",          sum(report$status == "csv_only_not_in_snapshot"))
