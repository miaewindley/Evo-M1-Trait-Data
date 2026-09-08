## Hanson et al. 2018 - analysis : combine derived Table 2 + Table 3 -> analysis CSV
## One row per striatal Region x Group (WS, TD) with neuron/glia density, glia:neuron ratio, soma area,
## and (dC/mC only) oligodendrocyte density + oligodendrocyte % of glia. Study 1a uses the TD group.

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
folder <- dirname(.sp); item_name <- "Hanson_etal_2018"
base <- local({ d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_ })
setwd(folder); options(scipen = 999, stringsAsFactors = FALSE)

t2 <- read.csv("Hanson_etal_2018_Table2_derived.csv", check.names = FALSE)
t3 <- read.csv("Hanson_etal_2018_Table3_derived.csv", check.names = FALSE)

m <- merge(t2, t3[, c("Region_code","Group","Oligodendrocyte_density.per.mm3",
                      "Oligodendrocyte_density.per.mm3.SD","Oligodendrocyte_pct_of_glia")],
           by = c("Region_code","Group"), all.x = TRUE)
codes <- c("dC","mC","aP","NA")
final <- m[order(match(m$Region_code, codes), m$Group),
           c("Region","Region_code","Group","n","taxon",
             "Neuron_density.per.mm3","Neuron_density.per.mm3.SD",
             "Glia_density.per.mm3","Glia_density.per.mm3.SD",
             "Glia_Neuron_ratio","Glia_Neuron_ratio.SD",
             "Soma_area.um2","Soma_area.um2.SD",
             "Oligodendrocyte_density.per.mm3","Oligodendrocyte_density.per.mm3.SD",
             "Oligodendrocyte_pct_of_glia")]
write.csv(final, "Hanson_etal_2018_analysis.csv", row.names = FALSE)

## public TSVs (published source) - one per snapshot table
if (!is.na(base)) {
  td <- file.path(base, "__Public", "comparative-data"); if (!dir.exists(td)) dir.create(td, recursive = TRUE)
  write.table(read.csv("Hanson_etal_2018_Table2_derived.csv", check.names = FALSE),
              file.path(td, "10.1002%2Fdneu.22554_Table2.tsv"), sep = "\t", row.names = FALSE)
  write.table(read.csv("Hanson_etal_2018_Table3_derived.csv", check.names = FALSE),
              file.path(td, "10.1002%2Fdneu.22554_Table3.tsv"), sep = "\t", row.names = FALSE)
}
cat(sprintf("analysis: %d rows\n", nrow(final)))
print(final[final$Group=="TD", c("Region","Neuron_density.per.mm3","Glia_density.per.mm3","Glia_Neuron_ratio")], row.names = FALSE)
