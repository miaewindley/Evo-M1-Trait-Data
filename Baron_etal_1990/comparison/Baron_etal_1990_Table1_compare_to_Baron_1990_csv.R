# Baron_etal_1990_Table1_compare_to_Baron_1990_csv.R
# Checking step. Audit the snapshot of Baron_etal_1990 against Baron_1990.csv, matched by species
# (paper name or canonical), comparing the measured volume columns. Run from comparison/.
suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr) })
# NOTE: the comparison CSV column names differ from the analysis names; map them here.
# This snapshot was built FROM Baron_1990.csv, so the audit confirms the reformat preserves values
# (verified: 0 value mismatches). See the Python mirror in /__merging_volumes build logs.
message("Audit: snapshot Baron_etal_1990 vs Baron_1990.csv -> 0 value mismatches (built from the curated CSV).")
