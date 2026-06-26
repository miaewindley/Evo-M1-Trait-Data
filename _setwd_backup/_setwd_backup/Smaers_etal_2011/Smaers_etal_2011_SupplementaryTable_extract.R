# Smaers_etal_2011_SupplementaryTable_extract.R
#
# EXTRACTION step (source -> snapshot), now traceable. The two supplementary tables
# were originally typed in by hand; this script regenerates the snapshots from the
# Adobe-Acrobat "Export PDF -> Excel" of the supplementary-tables PDF, so the
# source->snapshot step is reproducible.
#
# Source : 000323671_sm_suppltables.xlsx  (Adobe export of 000323671_sm_suppltables.pdf)
#          sheet "Table 1" = Suppl. Table 1 data (frontal white/grey L/R + total brain)
#          sheet "Table 2" = Suppl. Table 1 CAPTION (the table topic, split onto its own sheet)
#          sheet "Table 3" = Suppl. Table 2 data (5th-section white/grey L/R)
#          sheet "Table 4" = Suppl. Table 2 caption
# Output : Smaers_etal_2011_SupplementaryTable1_snapshot.csv
#          Smaers_etal_2011_SupplementaryTable2_snapshot.csv
#
# The Adobe export has data only (no header row) and drops the captions onto separate
# sheets; this script supplies the printed column headers. Values are taken verbatim
# (no cleaning here — that is the .R reformat step).

suppressPackageStartupMessages({ library(readxl); library(readr) })
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
  setwd("/Users/crossmodal/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/_setwd_backup/_setwd_backup/Smaers_etal_2011")
xlsx <- "000323671_sm_suppltables.xlsx"

st1 <- read_excel(xlsx, sheet = "Table 1", col_names = FALSE)
names(st1) <- c("Individual","Frontal left white","Frontal left grey",
                "Frontal right white","Frontal right grey","Total brain size")
write_csv(st1, "Smaers_etal_2011_SupplementaryTable1_snapshot.csv")

st2 <- read_excel(xlsx, sheet = "Table 3", col_names = FALSE)
names(st2) <- c("Individual","Section interval 5 left white","Section interval 5 left grey",
                "Section interval 5 right white","Section interval 5 right grey")
write_csv(st2, "Smaers_etal_2011_SupplementaryTable2_snapshot.csv")

message("Extracted snapshots from Adobe export: ST1 ", nrow(st1), " indiv, ST2 ", nrow(st2), " indiv.")
