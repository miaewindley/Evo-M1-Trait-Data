## Karlsen & Pakkenberg 2011 - analysis : combine -> analysis CSV  [Study 1a]
## Combines published Table 2 volumes (Table2_derived) with the neocortical cell composition
## GROUP MEANS (authordata_groupmeans.csv). The group means are derived from raw counting workbooks
## provided by B. Pakkenberg (personal communication) - see ReadMe; raw data restricted (not here).

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
folder <- dirname(.sp); item_name <- "Karlsen_Pakkenberg_2011"
base <- local({ d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_ })
setwd(folder); options(scipen = 999, stringsAsFactors = FALSE)

cells <- read.csv("Karlsen_Pakkenberg_2011_authordata_groupmeans.csv", check.names = FALSE)
vol   <- read.csv("Karlsen_Pakkenberg_2011_Table2_derived.csv", check.names = FALSE)
## harmonise region label: Table 2 uses "Total neocortex"; author data uses "Neocortex total"
vol$Region <- ifelse(vol$Region == "Total neocortex", "Neocortex total", vol$Region)

m <- merge(cells, vol[, c("Region","Group","Volume.cm3","Surface.cm2","Thickness.mm")],
           by = c("Region","Group"), all.x = TRUE)
ord <- c("Frontal","Temporal","Parietal","Occipital","Neocortex total")
m <- m[order(match(m$Region, ord), m$Group), ]
write.csv(m, "Karlsen_Pakkenberg_2011_analysis.csv", row.names = FALSE)

## public TSVs: published Table 2 (safe) + author-derived group means (personal communication - flagged)
if (!is.na(base)) {
  td <- file.path(base, "__Public", "comparative-data"); if (!dir.exists(td)) dir.create(td, recursive = TRUE)
  write.table(vol,   file.path(td, "10.1093%2Fcercor%2Fbhr033_Table2.tsv"),    sep = "\t", row.names = FALSE)
  write.table(cells, file.path(td, "10.1093%2Fcercor%2Fbhr033_authordata.tsv"), sep = "\t", row.names = FALSE)
}
cat("analysis rows:", nrow(m), "\n")
print(m[m$Group=="Control", c("Region","Neuron_density.x10.6.per.cm3","Glia_density.x10.6.per.cm3","Volume.cm3")], row.names = FALSE)
