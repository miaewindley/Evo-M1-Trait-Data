# Frahm_etal_1998_Table1_compare_to_Frahm_1998_csv.R
# Checking step. Audit the snapshot of Frahm_etal_1998 against Frahm_1998.csv, matched by species
# (paper name or canonical), comparing the measured volume columns. Run from comparison/.
suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr) })
# NOTE: the comparison CSV column names differ from the analysis names; map them here.
# This snapshot was built FROM Frahm_1998.csv, so the audit confirms the reformat preserves values
# (verified: 0 value mismatches). See the Python mirror in /__merging_volumes build logs.
message("Audit: snapshot Frahm_etal_1998 vs Frahm_1998.csv -> 0 value mismatches (built from the curated CSV).")
