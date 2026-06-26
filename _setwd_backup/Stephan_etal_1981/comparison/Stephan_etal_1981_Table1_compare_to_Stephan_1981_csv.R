# Stephan_etal_1981_Table1_compare_to_Stephan_1981_csv.R
#
# Checking step (self-contained in comparison/). Audit the snapshot of Stephan,
# Frahm & Baron (1981) Table 1 against Stephan_1981.csv, matched by the 1981
# species name, comparing every shared structure-volume column (and the per-range
# n columns). The snapshot was assembled from this CSV, so this confirms the
# transcription/assembly is faithful (expected: all matched, 0 mismatches).
# Run from comparison/.
#
# Inputs : ../Stephan_etal_1981_Table1_snapshot.xlsx (sheet Table1) ; Stephan_1981.csv
# Outputs: Stephan_etal_1981_Table1_comparison_report_from_R.csv
#          Stephan_etal_1981_Table1_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr) })
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/Stephan_etal_1981/comparison")
}

snapshot_file   <- "../Stephan_etal_1981_Table1_snapshot.xlsx"
snapshot_sheet  <- "Table1"
comparison_file <- "Stephan_1981.csv"
out_detail      <- "Stephan_etal_1981_Table1_comparison_report_from_R.csv"
out_mismatch    <- "Stephan_etal_1981_Table1_comparison_mismatches_from_R.csv"

parse_value <- function(x) parse_number(as.character(x), na = c("", "-", "NA", "n.a.", "__"))
norm_name   <- function(x) str_replace_all(tolower(replace_na(x, "")), "[^a-z0-9]", "")
clean <- function(h) ifelse(str_detect(h, "^n \\("),
  paste0("n_", str_replace_all(str_extract(h, "(?<=\\()[^)]+"), "\\s*to\\s*|\\s+", "_")),
  str_replace_all(str_squish(str_remove(h, "\\s*\\(\\d+\\)$")), " ", "_"))

# --- snapshot (row1 caption, row2 header, row3+ data) ---
raw <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
hdr <- clean(as.character(unlist(raw[2, ], use.names = FALSE)))
snap <- raw[-(1:2), , drop = FALSE]; names(snap) <- hdr
snap <- snap %>% filter(!is.na(species), str_squish(species) != "") %>% rename(Species_Stephan1981 = species)

# measurement columns = everything except the two identifiers
meas_cols <- setdiff(names(snap), c("code", "Species_Stephan1981"))

# --- CSV ---
csv <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!str_starts(replace_na(Species, ""), "AAAA_"),
         !is.na(Species_Stephan1981), Species_Stephan1981 != "")

# map each snapshot measurement column to a CSV column by normalised name
csv_lookup <- setNames(names(csv), norm_name(names(csv)))
# unname(): csv_lookup[...] is a named vector (names = normalised keys); without this the
# names make tidyselect all_of() treat csv_col as a rename spec, so the later pivot_longer
# can't find the original column names.
pairs <- tibble(col = meas_cols, csv_col = unname(csv_lookup[norm_name(meas_cols)])) %>% filter(!is.na(csv_col))

snap_long <- snap %>%
  transmute(key = norm_name(Species_Stephan1981), Species_Stephan1981,
            across(all_of(pairs$col), parse_value)) %>%
  pivot_longer(all_of(pairs$col), names_to = "col", values_to = "snap")
csv_long <- csv %>%
  transmute(key = norm_name(Species_Stephan1981),
            across(all_of(pairs$csv_col), parse_value)) %>%
  pivot_longer(all_of(pairs$csv_col), names_to = "csv_col", values_to = "csv") %>%
  left_join(pairs, by = "csv_col")

report <- full_join(snap_long, csv_long, by = c("key", "col")) %>%
  mutate(match = (is.na(snap) & is.na(csv)) | (!is.na(snap) & !is.na(csv) & abs(snap - csv) <= 1e-6))
write_csv(report, out_detail)
write_csv(filter(report, !match), out_mismatch)

message("species matched: ", n_distinct(report$key),
        " | columns compared: ", nrow(pairs),
        " | cell value mismatches: ", sum(!report$match, na.rm = TRUE))
