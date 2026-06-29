# Sherwood et al. 2004 (I) - Tables 4 & 5 reformat
# Sherwood CC et al. (2004). Brain Behav Evol (doi:10.1159/000075672).
# NOTE: this is GLI (grey-level index) cytoarchitecture of primary motor cortex
# (M1), NOT brain-structure volume data -> it is NOT part of the volume merge.
# Built to the 4-file convention as a standalone cytoarchitecture dataset.
#
# Table 4 = species mean GLI by cortical layer (II, III, V, VI) + cortical mean (+SEM).
# Table 5 = species mean values for 10 GLI profile feature vectors
#           (moment descriptors: meany/meanx/sd/skew/kurt for the original .o and
#            derivative .d profiles).

## ---- paths: self-contained (Rscript or RStudio; full repo or lone folder) ----
.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)             # Rscript file.R
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getSourceEditorContext()$path                    # RStudio: Source
    if (!nzchar(p)) p <- rstudioapi::getActiveDocumentContext()$path  # RStudio: Run
    if (nzchar(p)) return(normalizePath(p))
  }
  stop("Run with Rscript file.R, or open in RStudio and click Source (save first).", call. = FALSE)
})
folder <- paper_dir <- dirname(.sp)                                   # this paper's folder
item_name <- table_name <- tools::file_path_sans_ext(basename(.sp))  # = file name (matches __ReadMe.xlsx)
base <- dataset_root <- local({                                      # repo root; NA if run as a lone folder
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)

library(tidyverse); library(readxl)
base <- base
folder <- file.path(base, "Sherwood_etal_2004_I")
xls <- file.path(folder, "Sherwood_etal_2004_l.xlsx")

# Frozen faithful snapshots (as printed; Table 5 is transposed in print).
write_csv(read_excel(xls, sheet = "publishedTable4", col_names = FALSE),
          file.path(folder, "Sherwood_etal_2004_I_Table4_snapshot.csv"))
write_csv(read_excel(xls, sheet = "publishedTable5", col_names = FALSE),
          file.path(folder, "Sherwood_etal_2004_I_Table5_snapshot.csv"))

# Clean, analysis-ready tidy tables (species in rows).
t4 <- read_excel(xls, sheet = "reformattedTable4") %>% mutate(source = "Sherwood_etal_2004_I")
t5 <- read_excel(xls, sheet = "reformattedTable5") %>% mutate(source = "Sherwood_etal_2004_I")
write_csv(t4, file.path(folder, "Sherwood_etal_2004_I_Table4.csv"))
write_csv(t5, file.path(folder, "Sherwood_etal_2004_I_Table5.csv"))

message("Sherwood 2004_I: Table4 ", nrow(t4), " species; Table5 ", nrow(t5), " species (GLI, non-volume).")
