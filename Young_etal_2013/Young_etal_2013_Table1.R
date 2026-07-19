## Young, Collins & Kaas 2013, Front Neural Circuits 7:30 — Table 1
## doi:10.3389/fncir.2013.00030 · Team Kaas (Vanderbilt) · flow/isotropic fractionator.
## PRIMARY MOTOR CORTEX (M1) mass, surface area, and cell/neuron densities for 6 primate species
## (7 rows: two Papio labels = homotypic synonyms). This is a REGIONAL (M1) companion to
## Collins et al. 2010 (whole cortex): the Otolemur garnettii and Aotus nancymaae specimens are the
## same Vanderbilt animals -> flagged `specimen_overlap_Collins2010` so they are NOT double-counted
## with Collins at the whole-cortex level. Snapshot frozen; all cleaning here (golden rule).

options(scipen = 999)
## ---- paths: self-contained ----
.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getSourceEditorContext()$path
    if (!nzchar(p)) p <- rstudioapi::getActiveDocumentContext()$path
    if (nzchar(p)) return(normalizePath(p))
  }
  stop("Run with Rscript file.R, or open in RStudio and Source (save first).", call. = FALSE)
})
folder    <- dirname(.sp)
item_name <- tools::file_path_sans_ext(basename(.sp))          # Young_etal_2013_Table1
paper_doi <- "10.3389%2Ffncir.2013.00030"                      # disambiguates the 2 Young_etal_2013_Table1 rows
base      <- local({
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)
library(readxl)

raw <- as.data.frame(read_excel("Young_etal_2013_Table1_snapshot.xlsx", sheet = "reformatted"))
raw <- raw[!is.na(raw$Species), ]

## helpers: values printed "N/A" -> NA; SD printed " ± 0.02" -> 0.02
num <- function(x) suppressWarnings(as.numeric(ifelse(trimws(x) %in% c("", "N/A", "NA"), NA, x)))
sdn <- function(x) suppressWarnings(as.numeric(sub(".*?([-+]?[0-9]*\\.?[0-9]+).*", "\\1",
                     ifelse(trimws(x) %in% c("", "N/A", "NA"), NA, x))))

sp_fix  <- c("Saimiri sciuresis" = "Saimiri sciureus")           # printed typo
overlap <- c("Otolemur garnettii" = "likely_same_specimens",     # Vanderbilt = Collins 2010 galagos
             "Aotus nancymaae"    = "likely_same_specimens",     # Vanderbilt = Collins 2010 owl monkey
             "Saimiri sciureus"   = "no", "Macaca nemestrina" = "no",
             "Papio cynocephalus anubis" = "unconfirmed",        # Collins baboon = case 09-27 (Washington)
             "Papio hamadryas anubis"    = "unconfirmed", "Pan troglodytes" = "no")

acc <- ifelse(raw$Species %in% names(sp_fix), sp_fix[raw$Species], raw$Species)

clean <- data.frame(
  Species              = acc,
  species_as_published = raw$`Species published`,
  species_note         = raw$`Species note`,
  specimen_source      = raw$Specimen,
  n_hemispheres        = num(raw$`n cortical hemispheres`),
  M1_mass_g                 = num(raw$`M1 Mass (g)`),                       M1_mass_g_sd = sdn(raw$`M1 Mass (g) SD`),
  M1_pct_total_mass         = num(raw$`M1 Percent total mass`),             M1_pct_total_mass_sd = sdn(raw$`M1 Percent total mass SD`),
  M1_area_mm2               = num(raw$`M1 Area (mm2)`),                     M1_area_mm2_sd = sdn(raw$`M1 Area (mm2) SD`),
  M1_pct_total_area         = num(raw$`M1 Percent total area`),             M1_pct_total_area_sd = sdn(raw$`M1 Percent total area SD`),
  M1_cell_density_per_g_M   = num(raw$`M1 Cell density (millions) Cells/g`),M1_cell_density_per_g_M_sd = sdn(raw$`M1 Cell density (millions) Cells/g SD`),
  M1_cell_density_per_mm2_M = num(raw$`M1 Cell density (millions) Cells/mm2`),M1_cell_density_per_mm2_M_sd = sdn(raw$`M1 Cell density (millions) Cells/mm2 SD`),
  M1_pct_neurons            = num(raw$`Percent neurons in M1 (%)`),         M1_pct_neurons_sd = sdn(raw$`Percent neurons in M1 (%) SD`),
  M1_neuron_density_per_g_M = num(raw$`Neuron density (millions) Neurons/g`),M1_neuron_density_per_g_M_sd = sdn(raw$`Neuron density (millions) Neurons/g SD`),
  M1_neuron_density_per_mm2_M = num(raw$`Neuron density (millions) Neurons/mm2`),M1_neuron_density_per_mm2_M_sd = sdn(raw$`Neuron density (millions) Neurons/mm2 SD`),
  M1_pct_neuron_diff_from_avg = num(raw$`Percent neuron difference from total average (%)`),
  M1_pct_neuron_diff_from_avg_sd = sdn(raw$`Percent neuron difference from total average (%) SD`),
  specimen_overlap_Collins2010 = unname(overlap[acc]),
  source = item_name, stringsAsFactors = FALSE, check.names = FALSE
)

csv_file <- file.path(folder, paste0(item_name, ".csv"))
write.csv(clean, csv_file, row.names = FALSE)
message(item_name, ": ", nrow(clean), " rows written to ", basename(csv_file))

## ---- public TSV: resolve the code by (Item name AND this paper's DOI) — the name is shared by the
##      epileptic-baboon table (folder _b), so match on DOI to pick the M1 row ----
if (!is.na(base) && file.exists(file.path(base, "__ReadMe.xlsx"))) {
  fc <- readxl::read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
  hit <- which(fc$`Item name` == item_name & grepl(paper_doi, fc$`Item encoded`, fixed = TRUE))
  item_encoded <- if (length(hit)) fc$`Item encoded`[hit[1]] else NA_character_
  tsv_dir <- file.path(base, "__Public", "comparative-data")
  if (is.na(item_encoded)) warning("No M1 'Item encoded' found; TSV skipped.")
  else if (!dir.exists(path.expand(tsv_dir))) warning("Shared folder not found; TSV skipped.")
  else {
    write.table(clean, file.path(path.expand(tsv_dir), paste0(item_encoded, ".tsv")),
                sep = "\t", row.names = FALSE)
    message("Wrote ", item_encoded, ".tsv")
  }
}
