## Morgan et al. 2014 - analysis : derived -> analysis CSV
## Whole-amygdala per-individual cell numbers + volume, with derived numerical densities (cells/mm3)
## and glia:neuron ratio. Density = count / amygdala volume (hemisphere-invariant). Study 1a uses the
## Control group; both groups kept per-individual here.

.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getSourceEditorContext()$path
    if (!nzchar(p)) p <- rstudioapi::getActiveDocumentContext()$path
    if (nzchar(p)) return(normalizePath(p))
  }
  stop("Run with Rscript file.R, or open in RStudio and Source.", call. = FALSE)
})
folder <- dirname(.sp); item_name <- "Morgan_etal_2014_DataS1"
base <- local({ d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_ })
setwd(folder); options(scipen = 999, stringsAsFactors = FALSE)

d <- read.csv("Morgan_etal_2014_DataS1_derived.csv", check.names = FALSE)
out <- data.frame(
  Case = d$Case, Diagnosis = d$Diagnosis, Age_years = d$`Age (years)`, PMI_hours = d$`PMI (hours)`,
  Hemisphere = d$Hemisphere, Region = "Amygdala", taxon = "Homo sapiens",
  Amyg_Volume.mm3   = d$`Amyg Volume`,
  Neuron_N          = d$Whole_Num_Neuron,
  Glia_N            = d$Whole_Num_Glia,
  Astrocyte_N       = d$Whole_Num_Astro,
  Oligodendrocyte_N = d$Whole_Num_Olig,
  Microglia_N       = d$Whole_Num_Micro,
  Endothelial_N     = d$Whole_Num_Endo,
  stringsAsFactors = FALSE)
out$Neuron_density.per.mm3          <- out$Neuron_N          / out$Amyg_Volume.mm3
out$Glia_density.per.mm3            <- out$Glia_N            / out$Amyg_Volume.mm3
out$Astrocyte_density.per.mm3       <- out$Astrocyte_N       / out$Amyg_Volume.mm3
out$Oligodendrocyte_density.per.mm3 <- out$Oligodendrocyte_N / out$Amyg_Volume.mm3
out$Microglia_density.per.mm3       <- out$Microglia_N       / out$Amyg_Volume.mm3
out$Glia_Neuron_ratio               <- out$Glia_N            / out$Neuron_N
write.csv(out, "Morgan_etal_2014_analysis.csv", row.names = FALSE)

if (!is.na(base)) {
  td <- file.path(base, "__Public", "comparative-data"); if (!dir.exists(td)) dir.create(td, recursive = TRUE)
  write.table(out, file.path(td, "10.1371%2Fjournal.pone.0110356_DataS1.tsv"), sep = "\t", row.names = FALSE)
}
cat(sprintf("analysis: %d individuals (%d Control, %d ASD)\n",
            nrow(out), sum(out$Diagnosis=="Control"), sum(out$Diagnosis=="ASD")))
