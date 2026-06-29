# Bauernfeind_etal_2013_Table3.R
#
# Preparation step. Turn the journal-faithful snapshot of Bauernfeind et al. (2013)
# Table 3 -- SPECIES AVERAGES (mean +/- SD) of left and right insular subdivision
# volumes in humans and great apes -- into a tidy, analysis-ready CSV. Output comes
# from the snapshot only.
#
# Table 3 is the species-mean summary of the per-individual Tables 1 (left) and 2
# (right). It is kept as its own faithful snapshot/CSV for traceability; the merge
# (__merging_volumes) recomputes species means from the per-individual tables.
#
# Snapshot layout (Bauernfeind_etal_2013_Table3_snapshot.xlsx, sheet Table3): one header
# row, then 6 species rows. Two side-by-side blocks (left | right), each: n + the five
# subdivisions (Granular, Dysgranular, Agranular, FI, Total) printed as "mean +/- SD"
# (single value where n = 1). Volumes are cm3, exactly as printed.
#
# THIS script reshapes to tidy long form, splitting "mean +/- SD" into numeric mean / sd
# and converting cm3 -> mm3 (x1000).
#
# Input  : Bauernfeind_etal_2013_Table3_snapshot.xlsx   sheet: Table3
# Output : Bauernfeind_etal_2013_Table3.csv   (Species x hemisphere x subdivision, long)

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

suppressPackageStartupMessages({
  library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr)
})
setwd(folder)
options(scipen = 999)

raw <- read_excel("Bauernfeind_etal_2013_Table3_snapshot.xlsx", sheet = "Table3", col_types = "text")

split_mean <- function(x) suppressWarnings(as.numeric(str_trim(str_extract(x, "^[^\u00b1]+"))))
split_sd   <- function(x) suppressWarnings(as.numeric(str_trim(str_extract(x, "(?<=\u00b1).+"))))

subdiv <- c("Granular", "Dysgranular", "Agranular", "FI", "Total")
long <- bind_rows(lapply(c("left", "right"), function(side) {
  cols <- paste0(subdiv, "_", side)
  raw %>%
    select(Species, n = all_of(paste0("n_", side)), all_of(cols)) %>%
    pivot_longer(all_of(cols), names_to = "subdivision", values_to = "cell") %>%
    mutate(Species     = str_squish(Species),
           hemisphere  = side,
           n           = as.integer(n),
           subdivision = str_remove(subdivision, paste0("_", side)),
           mean_mm3    = split_mean(cell) * 1000,
           sd_mm3      = split_sd(cell)   * 1000) %>%
    select(Species, hemisphere, n, subdivision, mean_mm3, sd_mm3)
}))

write.csv(long, "Bauernfeind_etal_2013_Table3.csv", row.names = FALSE)
message("Wrote Bauernfeind_etal_2013_Table3.csv  (", nrow(long), " rows = ",
        n_distinct(long$Species), " species x 2 hemispheres x ", length(subdiv), " subdivisions)")
