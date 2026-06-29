# Barbeito-Andres et al. 2019 - developmental / experimental mouse dataset.
# "Region-specific changes in Mus musculus brain size and cell composition under
#  chronic nutrient restriction." J Exp Biol.
#
# Source: data_figshare.xlsx, sheet Hoja1 (sheets Hoja2/Hoja3 are EMPTY). Hoja1
# stacks THREE sub-tables:
#   (1) Absolute volumes (mm3)  - per specimen, 13 regions (rows 5-30)
#   (2) Cell number             - per specimen, 5 region groups x {Total,Neurons,
#                                 Non-neurons} (rows 34-48)
#   (3) Cell density            - same layout (rows 55-69)
# Groups (chronic nutrient restriction): C = control, LP = low protein,
#   LCP = low calorie + protein (labels as published).
#
# This is a SEPARATE comparison set (single species, experimental groups); it is
# NOT part of the phylogenetic volume merge.
#
# Output: 3 faithful snapshots + one tidy long table aligned to a generic schema
#   (species, reference, group, specimen, region, cell_type, measure, value, units).

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

suppressPackageStartupMessages({ library(readxl); library(readr); library(dplyr); library(tidyr); library(stringr) })
base <- base
folder <- file.path(base, "BarbeitoAndres_etal_2019")
xls <- file.path(folder, "data_figshare.xlsx")
numv <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x))))
raw <- read_excel(xls, sheet = "Hoja1", col_names = FALSE)

## ---- Block 1: absolute volumes (mm3) ----
vol_regions <- c("Olfactory_bulbs","Cerebellum","Corpus_callosum","Midbrain","Lateral_ventricle",
                 "Striatum","Cortex","Hypothalamus","Third_ventricle","Hippocampus","Thalamus",
                 "Fimbria","Total")              # row 4 cols 3:15, as published (cleaned)
b1 <- raw[5:30, ]
names(b1)[1:15] <- c("specimen","group", vol_regions)
b1 <- b1 %>% filter(!is.na(group)) %>%
  mutate(specimen = as.character(specimen), group = as.character(group))
write_csv(b1, file.path(folder, "BarbeitoAndres_etal_2019_volumes_snapshot.csv"))
vol_long <- b1 %>%
  pivot_longer(all_of(vol_regions), names_to = "region", values_to = "value") %>%
  transmute(species = "Mus musculus", reference = "BarbeitoAndres_etal_2019",
            group, specimen, region, cell_type = NA_character_,
            measure = "absolute_volume", value = numv(value), units = "mm3") %>%
  filter(!is.na(value))

## ---- Blocks 2 & 3: cell number / cell density ----
cell_regions <- c("Cerebellum","Cortex","Olfactory","Hippocampus","Rest")
cell_cols <- as.vector(t(outer(cell_regions, c("Total","Neurons","Non_neurons"), paste, sep = "__")))
parse_cell <- function(rows, measure, units) {
  blk <- raw[rows, ]
  names(blk)[1] <- "group"; names(blk)[2:16] <- cell_cols
  blk <- blk %>% filter(!is.na(group), group %in% c("C","LP","LCP")) %>%
    mutate(group = as.character(group))
  list(snapshot = blk,
       long = blk %>% pivot_longer(all_of(cell_cols), names_to = "rc", values_to = "value") %>%
         separate(rc, into = c("region","cell_type"), sep = "__") %>%
         transmute(species = "Mus musculus", reference = "BarbeitoAndres_etal_2019",
                   group, specimen = NA_character_, region,
                   cell_type = gsub("Non_neurons","Non-neurons", cell_type),
                   measure = measure, value = numv(value), units = units) %>%
         filter(!is.na(value)))
}
n2 <- parse_cell(34:48, "cell_number",  "cells")
n3 <- parse_cell(55:69, "cell_density", "cells_per_mg (as published; verify against paper)")
write_csv(n2$snapshot, file.path(folder, "BarbeitoAndres_etal_2019_cellnumber_snapshot.csv"))
write_csv(n3$snapshot, file.path(folder, "BarbeitoAndres_etal_2019_celldensity_snapshot.csv"))

## ---- combined tidy long ----
tidy <- bind_rows(vol_long, n2$long, n3$long)
write_csv(tidy, file.path(folder, "BarbeitoAndres_etal_2019_tidy.csv"))

message("Barbeito 2019: volumes ", nrow(vol_long), " | cell_number ", nrow(n2$long),
        " | cell_density ", nrow(n3$long), " -> tidy ", nrow(tidy), " rows.")
