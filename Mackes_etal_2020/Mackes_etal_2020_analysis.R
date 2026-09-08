## Mackes/ERA - analysis : combine cortical (ERABIS) + subcortical derived -> analysis CSV
## Per-hemisphere volume per region per adoptee group (UK, Romanian). Group-level; ERA personal
## communication (see ReadMe). Cerebral cortex = sum of Desikan-Killiany parcels, averaged L/R.

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
folder <- dirname(.sp); item_name <- "Mackes_etal_2020"
base <- local({ d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_ })
setwd(folder); options(scipen = 999, stringsAsFactors = FALSE)

cort <- read.csv("Mackes_etal_2020_ERABIS_derived.csv", check.names = FALSE)
sub  <- read.csv("Mackes_etal_2020_subcortical_derived.csv", check.names = FALSE)

## cerebral cortex GM per hemisphere = sum of parcels, averaged L/R
cx <- do.call(rbind, lapply(c("UK","Romanian"), function(g) {
  s <- cort[cort$Group == g & cort$Hemisphere %in% c("L","R"), ]
  lh <- sum(s$mean.mm3[s$Hemisphere=="L"], na.rm=TRUE); rh <- sum(s$mean.mm3[s$Hemisphere=="R"], na.rm=TRUE)
  data.frame(Region = "Cerebral cortex", Group = g, n = ifelse(g=="UK",21L,67L),
             taxon = "Homo sapiens", Volume_per_hemisphere.cm3 = round((lh+rh)/2/1000, 4))
}))
sc <- sub[, c("Region","Group","n","taxon","Volume_per_hemisphere.cm3")]
out <- rbind(cx, sc)
ord <- c("Cerebral cortex","Thalamus","Caudate","Putamen","Pallidum","Hippocampus","Amygdala","Nucleus Accumbens")
out <- out[order(match(out$Region, ord), out$Group), ]
write.csv(out, "Mackes_etal_2020_analysis.csv", row.names = FALSE)

if (!is.na(base)) {
  td <- file.path(base, "__Public", "comparative-data"); if (!dir.exists(td)) dir.create(td, recursive = TRUE)
  write.table(cort, file.path(td, "10.1073%2Fpnas.1911264116_ERABIS.tsv"),      sep = "\t", row.names = FALSE)
  write.table(sub,  file.path(td, "10.1073%2Fpnas.1911264116_subcortical.tsv"), sep = "\t", row.names = FALSE)
}
cat("analysis rows:", nrow(out), "\n"); print(out, row.names = FALSE)
