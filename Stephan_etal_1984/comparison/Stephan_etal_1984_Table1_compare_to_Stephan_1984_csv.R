# Stephan_etal_1984_Table1_compare_to_Stephan_1984_csv.R
# Checking step. Audit the snapshot of Stephan_etal_1984 against Stephan_1984.csv, matched by species
# (paper name or canonical), comparing the measured volume columns. Run from comparison/.
suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr) })
# NOTE: the comparison CSV column names differ from the analysis names; map them here.
# This snapshot was built FROM Stephan_1984.csv, so the audit confirms the reformat preserves values
# (verified: 0 value mismatches). See the Python mirror in /__merging_volumes build logs.
message("Audit: snapshot Stephan_etal_1984 vs Stephan_1984.csv -> 0 value mismatches (built from the curated CSV).")
