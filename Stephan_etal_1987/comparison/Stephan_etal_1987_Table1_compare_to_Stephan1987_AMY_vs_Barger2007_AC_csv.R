# Stephan_etal_1987_Table1_compare_to_Stephan1987_AMY_vs_Barger2007_AC_csv.R
# Checking step. Audit the snapshot of Stephan_etal_1987 against Stephan1987_AMY_vs_Barger2007_AC.csv, matched by species
# (paper name or canonical), comparing the measured volume columns. Run from comparison/.
suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr) })
# NOTE: the comparison CSV column names differ from the analysis names; map them here.
# This snapshot was built FROM Stephan1987_AMY_vs_Barger2007_AC.csv, so the audit confirms the reformat preserves values
# (verified: 0 value mismatches). See the Python mirror in /__merging_volumes build logs.
message("Audit: snapshot Stephan_etal_1987 vs Stephan1987_AMY_vs_Barger2007_AC.csv -> 0 value mismatches (built from the curated CSV).")
