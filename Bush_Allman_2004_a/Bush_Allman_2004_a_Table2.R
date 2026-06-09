## Bush, E.C. & Allman, J.M. (2004). The scaling of frontal cortex in primates and carnivores.
## PNAS 101(11):3962-3966.  Table 2 = "Volumes for cortical regions for 55 species of mammals (cm3)".
## Source: HTML download from the PNAS site (05760table2.html). Snapshot -> clean -> harmonize -> compare.

setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Bush_Allman_2004_a")
options(scipen = 999)
library(rvest); library(readxl)

## 1. SNAPSHOT (faithful) - parse the published HTML table verbatim
tab <- html_table(read_html("05760table2.html"))[[1]]
colnames(tab) <- c("species","FrG","RoG","FrRat","WhBr","NeoG","NeoW","Act","Diet","Gr","Grsz")
tab <- tab[-1, ]                                   # drop the repeated header row
write.csv(tab, "Bush_Allman_2004_a_Table2_snapshot.csv", row.names = FALSE)

## 2. HARMONIZE species names to the project key
key <- read.csv("../_keys/Stephan/species_key.csv", stringsAsFactors = FALSE)
lookup <- setNames(key$accepted_name, tolower(key$variant_name))
lookup <- c(lookup, setNames(key$accepted_name, tolower(key$accepted_name)))
harm <- function(s){ s <- trimws(s); cand <- paste0(toupper(substr(s,1,1)), tolower(substr(s,2,nchar(s))))
  v <- lookup[tolower(s)]; if (is.na(v)) v <- lookup[tolower(cand)]; if (is.na(v)) cand else unname(v) }
num <- function(x) suppressWarnings(as.numeric(x))

## 3. CLEAN (rename to interpretable columns; cm3)
clean <- data.frame(
  species              = vapply(tab$species, harm, character(1)),
  species_as_published = tab$species,
  frontal_grey_cm3        = num(tab$FrG),  rest_of_cortex_grey_cm3 = num(tab$RoG),
  frontal_ratio           = num(tab$FrRat),whole_brain_cm3         = num(tab$WhBr),
  neocortex_grey_cm3      = num(tab$NeoG), neocortex_white_cm3     = num(tab$NeoW),
  activity = tab$Act, diet = tab$Diet, group_type = tab$Gr, group_size = tab$Grsz,
  source = "Bush_Allman_2004_a", stringsAsFactors = FALSE)
write.csv(clean, "Bush_Allman_2004_a_Table2.csv", row.names = FALSE)
write.table(clean, "Bush_Allman_2004_a_Table2.tsv", sep = "\t", row.names = FALSE, quote = FALSE)

## 4. COMPARE to the digitized copy (comparison/bush_neocortex.xls)  -> comparison/check_Table2_vs_digitized.csv
## 5. COMPARE to a SIMILAR dataset: neocortex grey vs Frahm (Stephan_primates.csv NeoG_Frahm, mm3)
##    -> comparison/compare_NeoG_Bush_vs_Frahm.csv  (Bush runs ~3-12% smaller for shared primates)
## (both comparison CSVs are written by the accompanying build; see ReadMe.)
