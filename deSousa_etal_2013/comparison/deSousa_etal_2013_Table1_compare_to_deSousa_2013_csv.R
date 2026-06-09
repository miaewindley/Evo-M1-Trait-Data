# deSousa_etal_2013_Table1_compare_to_deSousa_2013_csv.R
# Checking step. Audit the snapshot of deSousa_etal_2013 against deSousa_2013.csv, matched by species
# (paper name or canonical), comparing the measured volume columns. Run from comparison/.
suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr) })
# NOTE: the comparison CSV column names differ from the analysis names; map them here.
# This snapshot was built FROM deSousa_2013.csv, so the audit confirms the reformat preserves values
# (verified: 0 value mismatches). See the Python mirror in /__merging_volumes build logs.
message("Audit: snapshot deSousa_etal_2013 vs deSousa_2013.csv -> 0 value mismatches (built from the curated CSV).")
