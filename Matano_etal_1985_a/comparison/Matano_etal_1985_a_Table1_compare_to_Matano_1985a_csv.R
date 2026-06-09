# Matano_etal_1985_a_Table1_compare_to_Matano_1985a_csv.R
#
# Checking step (self-contained in comparison/). Audit the journal-faithful
# snapshot of Matano et al. (1985) Part II (CEREBELLAR NUCLEI) Table I against
# Matano_1985a.csv, matched by species on EITHER the paper's name
# (Species_Matano1985a) OR the canonical Species, resolving each CSV row once (no
# phantom duplicates). Compares the four nuclear volumes (TCN, MCN, ICN, LCN),
# body weight, and n. Run from comparison/.
#
# Inputs : ../Matano_etal_1985_a_Table1_snapshot.xlsx (sheet Table1) ; Matano_1985a.csv
# Outputs: Matano_etal_1985_a_Table1_comparison_report_from_R.csv
#          Matano_etal_1985_a_Table1_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

snapshot_file     <- "../Matano_etal_1985_a_Table1_snapshot.xlsx"
snapshot_sheet    <- "Table1"
comparison_file   <- "Matano_1985a.csv"
output_detail     <- "Matano_etal_1985_a_Table1_comparison_report_from_R.csv"
output_mismatches <- "Matano_etal_1985_a_Table1_comparison_mismatches_from_R.csv"
header_rows       <- 3L
structures <- c("TCN","MCN","ICN","LCN","body_weight","n")
csv_col <- c(TCN = "Cerebellar_nuclei_total", MCN = "Medial_cerebellar_nuclei",
             ICN = "Interpositus_cerebellar_nuclei", LCN = "Lateral_cerebellar_nuclei",
             body_weight = "Body_weight_1985a", n = "Number_cerebellar_nuclei")

parse_value <- function(x) parse_number(as.character(x), na = c("", "-", "–", "—", "NA", "n.a.", "__"))
norm_label  <- function(x) str_squish(tolower(str_remove_all(x, "\\.")))

pos <- c("code","species_disp","n_raw","body_weight","TCN","MCN","ICN","LCN")
raw  <- read_excel(snapshot_file, sheet = snapshot_sheet, col_names = FALSE, col_types = "text")
sdat <- raw %>% slice(-(seq_len(header_rows))) %>% `names<-`(c(pos, rep(NA, max(0, ncol(.) - length(pos)))))
snap <- sdat %>%
  filter(!is.na(parse_value(TCN))) %>%
  transmute(species_key = norm_label(species_disp), species_snapshot = str_squish(species_disp),
            TCN_snap = parse_value(TCN), MCN_snap = parse_value(MCN),
            ICN_snap = parse_value(ICN), LCN_snap = parse_value(LCN),
            body_weight_snap = parse_value(body_weight), n_snap = parse_value(n_raw))

comp_raw <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!str_starts(replace_na(Species, ""), "AAAA_"),
         !is.na(.data[[csv_col[["TCN"]]]])) %>%
  mutate(.cid = row_number())
snap <- snap %>% mutate(.cid = dplyr::coalesce(
  comp_raw$.cid[match(species_key, norm_label(comp_raw$Species_Matano1985a))],
  comp_raw$.cid[match(species_key, norm_label(comp_raw$Species))]))
comp <- comp_raw %>% transmute(.cid,
  species_csv = str_squish(dplyr::coalesce(Species_Matano1985a, Species)),
  TCN_csv = parse_value(.data[[csv_col[["TCN"]]]]), MCN_csv = parse_value(.data[[csv_col[["MCN"]]]]),
  ICN_csv = parse_value(.data[[csv_col[["ICN"]]]]), LCN_csv = parse_value(.data[[csv_col[["LCN"]]]]),
  body_weight_csv = parse_value(.data[[csv_col[["body_weight"]]]]),
  n_csv           = parse_value(.data[[csv_col[["n"]]]]))

num_match <- function(a, b, tol = 1e-6) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
report <- full_join(snap, comp, by = ".cid") %>%
  mutate(status = case_when(is.na(species_snapshot) ~ "csv_only_not_in_snapshot",
                            is.na(species_csv)      ~ "snapshot_only_not_in_csv",
                            TRUE                    ~ "matched_by_species"))
for (s in structures)
  report[[paste0(s, "_match")]] <- num_match(report[[paste0(s, "_snap")]], report[[paste0(s, "_csv")]])
report$n_measure_mismatch <- rowSums(!as.matrix(report[paste0(structures, "_match")]), na.rm = TRUE)
report <- report %>% arrange(dplyr::coalesce(species_snapshot, species_csv)) %>%
  relocate(status, species_snapshot, species_csv, n_measure_mismatch)

write_csv(report, output_detail)
write_csv(filter(report, status != "matched_by_species" | n_measure_mismatch > 0), output_mismatches)
message("matched: ", sum(report$status == "matched_by_species"),
        " | value mismatches: ", sum(report$n_measure_mismatch > 0 & report$status == "matched_by_species", na.rm = TRUE),
        " | snapshot-only: ", sum(report$status == "snapshot_only_not_in_csv"),
        " | csv-only: ", sum(report$status == "csv_only_not_in_snapshot"),
        "  (Rattus & Spalax carry a TCN value but no paper species name -> expected csv-only additions)")
