## Kochiyama_etal_2018 — Figure 3
## Kochiyama, T., Tanabe, H. C., Sawada, R., Ogihara, N. et al. (2018).
## "Reconstructing the Neanderthal brain using computational anatomy."
## Scientific Reports 8:6296. DOI:10.1038/s41598-018-24331-0
##
## The numeric data for Figure 3 are printed in the figure LEGEND: the mean
## (+/- s.d.) modern-human (MH) volumes of the 13 parcellated brain regions (cc),
## plus the ANOVA F/p for the four regions with a significant relative-volume
## difference among NT / EH / MH. The NT and EH relative-volume bars in panel (a)
## are NOT given numerically in the text, so only the MH means + ANOVA are
## transcribed here.
##
## Snapshot -> clean. Golden rule: the snapshot is frozen/faithful; ALL cleaning
## (unit conversion, code -> structure mapping) happens here.

options(scipen = 999)

## ---- paths: self-contained (Rscript or RStudio; full repo or lone folder) ----
.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getSourceEditorContext()$path
    if (!nzchar(p)) p <- rstudioapi::getActiveDocumentContext()$path
    if (nzchar(p)) return(normalizePath(p))
  }
  stop("Run with Rscript file.R, or open in RStudio and click Source (save first).", call. = FALSE)
})
folder    <- dirname(.sp)
item_name <- tools::file_path_sans_ext(basename(.sp))
base      <- local({
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)

## row 1 = caption, row 2 = header, rows 3+ = the 13 regions
raw <- read.csv("Kochiyama_etal_2018_Figure3_snapshot.csv", skip = 1,
                check.names = FALSE, stringsAsFactors = FALSE, na.strings = c("", "NA"))

## code -> (canonical structure, subregion), from the figure-legend key
structure_map <- c(
  "Fr SM" = "FrontalLobe",   "Fr I" = "FrontalLobe",   "Fr O" = "FrontalLobe",
  "Sm"    = "SensorimotorCortex",
  "Pa SI" = "ParietalLobe",  "Pa TP" = "ParietalLobe",
  "Te SM" = "TemporalLobe",  "Te I" = "TemporalLobe",
  "Oc SM" = "OccipitalLobe", "Oc I" = "OccipitalLobe",
  "Ce V"  = "Cerebellum",    "Ce A" = "Cerebellum",    "Ce P" = "Cerebellum"
)
subregion_map <- c(
  "Fr SM" = "superior and middle region", "Fr I" = "inferior region",
  "Fr O"  = "orbitofrontal region",       "Sm"   = "whole (sensorimotor cortex)",
  "Pa SI" = "superior and inferior region","Pa TP"= "temporo-parietal junction",
  "Te SM" = "superior and middle region", "Te I" = "inferior region",
  "Oc SM" = "superior and middle region", "Oc I" = "inferior region",
  "Ce V"  = "vermis", "Ce A" = "anterior region", "Ce P" = "posterior region"
)

as_num <- function(x) suppressWarnings(as.numeric(x))

clean <- data.frame(
  Region_code        = raw$Region,
  Structure          = unname(structure_map[raw$Region]),
  Subregion          = unname(subregion_map[raw$Region]),
  Species            = "Homo sapiens",
  Group              = "MH",            # modern Homo sapiens (normalization reference)
  n_MH               = 1185L,           # df within = 2,1190 => MH n = 1185, NT = 4, EH = 4
  MH_mean_Vol.cc     = as_num(raw$MH_mean_cc),
  MH_sd_Vol.cc       = as_num(raw$MH_sd_cc),
  MH_mean_Vol.mm3    = round(as_num(raw$MH_mean_cc) * 1000),   # project unit: cc -> mm3
  MH_sd_Vol.mm3      = round(as_num(raw$MH_sd_cc)   * 1000),
  MH_relative_volume = 1.0,             # panel (a) normalizes each region to mean MH = 1
  ANOVA_F            = as_num(raw$ANOVA_F),
  ANOVA_p            = as_num(raw$ANOVA_p),
  significant        = !is.na(as_num(raw$ANOVA_p)),
  source             = "Kochiyama_etal_2018",
  stringsAsFactors   = FALSE
)

stopifnot(nrow(clean) == 13L)
stopifnot(!any(is.na(clean$Structure)))

csv_file <- file.path(folder, paste0(item_name, ".csv"))
write.csv(clean, csv_file, row.names = FALSE)
message(item_name, ": ", nrow(clean), " rows written to ", basename(csv_file))

tsv_dir <- file.path(base, "__Public", "comparative-data")
item_encoded <- if (!is.na(base) && file.exists(file.path(base, "__ReadMe.xlsx"))) {
  filecodes <- readxl::read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
  filecodes$`Item encoded`[match(item_name, filecodes$`Item name`)]
} else NA_character_

if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  tsv_file <- file.path(path.expand(tsv_dir), paste0(item_encoded, ".tsv"))
  write.table(clean, tsv_file, sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_file)
}
