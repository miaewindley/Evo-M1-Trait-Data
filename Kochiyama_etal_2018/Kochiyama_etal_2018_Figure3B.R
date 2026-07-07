## Kochiyama_etal_2018 — Figure 3B
## Absolute left/right cerebellar volumes (cc) read from Figure 3(b).
##
## This script intentionally handles Figure 3B only. Figure 3A is a separate item.

options(scipen = 999)
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
folder <- dirname(.sp)
item_name <- tools::file_path_sans_ext(basename(.sp))
setwd(folder)

structure_map <- c("Ce A"="Cerebellum", "Ce P"="Cerebellum")
subregion_map <- c("Ce A"="anterior", "Ce P"="posterior")
group_map <- c("NT"="Neanderthal", "EH"="early Homo sapiens", "MH"="modern Homo sapiens")

raw <- read.csv("Kochiyama_etal_2018_Figure3B_snapshot.csv", skip = 1,
                colClasses = "character", check.names = FALSE, na.strings = c("", "NA"))
as_num <- function(x) suppressWarnings(as.numeric(x))
clean <- data.frame(
  Region_code = rep(raw$Region, each = 2),
  Structure = unname(structure_map[rep(raw$Region, each = 2)]),
  Subregion = unname(subregion_map[rep(raw$Region, each = 2)]),
  Group_code = rep(raw$Group, each = 2),
  Group = unname(group_map[rep(raw$Group, each = 2)]),
  Hemisphere = rep(c("Left", "Right"), times = nrow(raw)),
  Volume_cc = as_num(c(rbind(raw$Left_cc, raw$Right_cc))),
  source = "Kochiyama_etal_2018",
  note = "Figure 3B; figure-digitized cerebellar volume estimate",
  stringsAsFactors = FALSE)
stopifnot(nrow(clean) == 12L, !anyNA(clean$Structure), !anyNA(clean$Subregion), !anyNA(clean$Group))
write.csv(clean, paste0(item_name, ".csv"), row.names = FALSE)
write.table(clean, "10.1038%2Fs41598-018-24331-0_Figure3B.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
message(item_name, ": ", nrow(clean), " rows")
