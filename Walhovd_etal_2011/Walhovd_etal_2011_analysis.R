## Walhovd et al. 2011 - analysis : derived -> analysis CSV
## Select the Study-2 regions (8 + total brain volume), map to canonical names, and provide bilateral
## mm3, bilateral cm3, and per-hemisphere cm3 (= bilateral/2, to match the ERA per-hemisphere convention).

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
folder <- dirname(.sp); item_name <- "Walhovd_etal_2011"
base <- local({ d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_ })
setwd(folder); options(scipen = 999, stringsAsFactors = FALSE)

d <- read.csv("Walhovd_etal_2011_derived.csv", check.names = FALSE)
canon <- c("Cerebral Cortex (GM)"="Cerebral cortex","Thalamus"="Thalamus","Caudate"="Caudate",
           "Putamen"="Putamen","Pallidum"="Pallidum","Hippocampus"="Hippocampus",
           "Amygdala"="Amygdala","Accumbens"="Nucleus Accumbens","Total volume"="Total brain volume")
d <- d[d$Structure %in% names(canon), ]
d$Region <- unname(canon[d$Structure])
out <- data.frame(
  Region = d$Region, Group = "Normative", n = 262L, taxon = "Homo sapiens",
  Volume_bilateral.mm3      = d$Overall_N262_mean.mm3,
  Volume_bilateral.cm3      = round(d$Overall_N262_mean.mm3/1000, 4),
  Volume_per_hemisphere.cm3 = round(d$Overall_N262_mean.mm3/1000/2, 4),
  Volume_bilateral_SD.mm3   = d$Overall_N262_SD.mm3,
  stringsAsFactors = FALSE)
ord <- c("Cerebral cortex","Thalamus","Caudate","Putamen","Pallidum","Hippocampus",
         "Amygdala","Nucleus Accumbens","Total brain volume")
out <- out[order(match(out$Region, ord)), ]
write.csv(out, "Walhovd_etal_2011_analysis.csv", row.names = FALSE)
if (!is.na(base)) {
  td <- file.path(base, "__Public", "comparative-data"); if (!dir.exists(td)) dir.create(td, recursive = TRUE)
  write.table(out, file.path(td, "10.1016%2Fj.neurobiolaging.2009.05.013_normative.tsv"), sep = "\t", row.names = FALSE)
}
cat("analysis:", nrow(out), "regions\n")
print(out[, c("Region","Volume_per_hemisphere.cm3")], row.names = FALSE)
