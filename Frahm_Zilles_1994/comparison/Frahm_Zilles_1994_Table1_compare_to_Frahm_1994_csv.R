# Frahm_Zilles_1994_Table1_compare_to_Frahm_1994_csv.R
#
# Checking step (self-contained in comparison/). Audit the journal-faithful
# snapshot of Frahm & Zilles (1994) (sheets Table1 + Table2, merged by species)
# against Frahm_1994.csv, matched by species on EITHER the paper's name
# (Species) OR the canonical Species, resolving each CSV row once (no
# phantom duplicates). Compares the ten shared measures: body weight, the three
# main hippocampal volumes (total, HP+HS fibres, retrocommissural) and the six
# retrohippocampal subfields (subiculum, CA1, CA2, CA3, hilus, fascia dentata).
# Run from comparison/.
#
# Inputs : ../Frahm_Zilles_1994_Table1_snapshot.xlsx (sheets Table1, Table2) ; Frahm_1994.csv
# Outputs: Frahm_Zilles_1994_Table1_comparison_report_from_R.csv
#          Frahm_Zilles_1994_Table1_comparison_mismatches_from_R.csv

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
## Set working directory to this script folder
setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Frahm_Zilles_1994/comparison")
snapshot_file     <- "../Frahm_Zilles_1994_Table1_snapshot.xlsx"
comparison_file   <- "Frahm_1994.csv"
output_detail     <- "Frahm_Zilles_1994_Table1_comparison_report_from_R.csv"
output_mismatches <- "Frahm_Zilles_1994_Table1_comparison_mismatches_from_R.csv"
header_rows       <- 2L
structures <- c("body_weight","hippocampus_total","HP_HS_fibers","hippocampus_retrocommissuralis",
                "subiculum","CA1","CA2","CA3","hilus","fascia_dentata")
csv_col <- c(body_weight="Body_weight_1994", hippocampus_total="Hippocampus_1994",
             HP_HS_fibers="HP_HS_fibers", hippocampus_retrocommissuralis="Hippocampus_retrocommissuralis",
             subiculum="Subiculum", CA1="CA1", CA2="CA2", CA3="CA3", hilus="Hilus", fascia_dentata="Fascia_dentata")

parse_value <- function(x) parse_number(as.character(x), na = c("", "-", "–", "—", "NA", "n.a.", "__"))
norm_label  <- function(x) str_squish(tolower(str_remove_all(x, "\\.")))

# --- snapshot side: merge the two sheets by species ---
p1 <- c("species_disp","body_weight","hippocampus_total","HP_HS_fibers","hippocampus_retrocommissuralis")
s1 <- read_excel(snapshot_file, sheet = "Table1", col_names = FALSE, col_types = "text") %>%
  slice(-(seq_len(header_rows))) %>% `names<-`(c(p1, rep(NA, max(0, ncol(.) - length(p1))))) %>%
  filter(!is.na(species_disp), !is.na(parse_value(hippocampus_total))) %>%
  transmute(species_key = norm_label(species_disp), species_snapshot = str_squish(species_disp),
            body_weight_snap = parse_value(body_weight), hippocampus_total_snap = parse_value(hippocampus_total),
            HP_HS_fibers_snap = parse_value(HP_HS_fibers),
            hippocampus_retrocommissuralis_snap = parse_value(hippocampus_retrocommissuralis))
p2 <- c("species_disp","subiculum","CA1","CA2","CA3","hilus","fascia_dentata")
s2 <- read_excel(snapshot_file, sheet = "Table2", col_names = FALSE, col_types = "text") %>%
  slice(-(seq_len(header_rows))) %>% `names<-`(c(p2, rep(NA, max(0, ncol(.) - length(p2))))) %>%
  filter(!is.na(species_disp), !is.na(parse_value(CA1))) %>%
  transmute(species_key = norm_label(species_disp),
            subiculum_snap = parse_value(subiculum), CA1_snap = parse_value(CA1), CA2_snap = parse_value(CA2),
            CA3_snap = parse_value(CA3), hilus_snap = parse_value(hilus), fascia_dentata_snap = parse_value(fascia_dentata))
snap <- left_join(s1, s2, by = "species_key")

# --- csv side: match on paper name OR canonical, resolve each row once ---
comp_raw <- read_csv(comparison_file, col_types = cols(.default = col_character()), na = c("")) %>%
  filter(!str_starts(replace_na(Species, ""), "AAAA_"),
         !is.na(.data[[csv_col[["hippocampus_total"]]]])) %>%
  mutate(.cid = row_number())
snap <- snap %>% mutate(.cid = dplyr::coalesce(
  comp_raw$.cid[match(species_key, norm_label(comp_raw$Species))],
  comp_raw$.cid[match(species_key, norm_label(comp_raw$Species))]))
# NOTE: building these columns via quote(...) inside lapply() previously failed with
# "object 's' not found" -- quote() captures the expression unevaluated, so the loop
# variable `s` was never substituted in and was looked up (and not found) later inside
# transmute()'s data mask. A plain loop avoids the metaprogramming pitfall entirely.
comp <- comp_raw %>% transmute(.cid, species_csv = str_squish(Species))
for (s in structures) {
  comp[[paste0(s, "_csv")]] <- parse_value(comp_raw[[csv_col[[s]]]])
}

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
        " | csv-only: ", sum(report$status == "csv_only_not_in_snapshot"))
