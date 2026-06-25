## Bush EC, Allman JM (2003). The scaling of white matter to gray matter in cerebellum
## and neocortex. Brain Behav Evol 61(1):1-5. Table 1.
##
## Build step only: frozen snapshot -> clean analysis CSV -> DOI-coded public TSV.
## Species are harmonised to the project key (printed name kept as species_as_published).
## QA against the compiled/digitised copies lives separately in comparison/ (run those
## scripts on their own; this build does not perform the comparison).
##
## Input : Bush_Allman_2003_Table1_snapshot.csv   (Group, Species, + 4 cm3 volume cols)
## Output: Bush_Allman_2003_Table1.csv            one row per species (45)
##         <Item encoded>.tsv in __Public/comparative-data/  (named from __ReadMe.xlsx)

options(scipen = 999)
base   <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"
folder <- file.path(base, "Bush_Allman_2003")
setwd(path.expand(folder))

## ---- read the frozen snapshot (verbatim headers) ----
snap <- read.csv("Bush_Allman_2003_Table1_snapshot.csv",
                 check.names = FALSE, stringsAsFactors = FALSE,
                 na.strings = c("", "NA", "n.a.", "-", "--"))

## ---- harmonise species to the project key (printed name preserved) ----
key    <- read.csv(file.path(base, "_keys/Allman/species_key.csv"), stringsAsFactors = FALSE)
lookup <- c(setNames(key$accepted_name, tolower(key$variant_name)),
            setNames(key$accepted_name, tolower(key$accepted_name)))
harm   <- function(s) { s <- trimws(s); v <- lookup[tolower(s)]
                        if (is.na(v)) s else unname(v) }
num    <- function(x) suppressWarnings(as.numeric(gsub(",", "", trimws(as.character(x)))))

## ---- clean (volumes kept in cm3, per the definitions; merge converts downstream) ----
clean <- data.frame(
  species              = vapply(snap$Species, harm, character(1), USE.NAMES = FALSE),
  species_as_published = trimws(snap$Species),
  group                = trimws(snap$Group),
  cer_white_cm3        = num(snap[["Cer White"]]),
  cer_gray_cm3         = num(snap[["Cer Gray"]]),
  neo_white_cm3        = num(snap[["Neo White"]]),
  neo_gray_cm3         = num(snap[["Neo Gray"]]),
  source               = "Bush_Allman_2003",
  stringsAsFactors = FALSE
)

write.csv(clean, "Bush_Allman_2003_Table1.csv", row.names = FALSE)
message("Bush & Allman 2003 Table 1: ", nrow(clean), " species written.")

## ---- public TSV: look up the DOI/PMID code from __ReadMe.xlsx (don't hardcode) ----
item_name    <- "Bush_Allman_2003_Table1"   # must match the registry Item name exactly
tsv_dir      <- file.path(base, "__Public/comparative-data/")
filecodes    <- readxl::read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]
if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' (DOI) for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
} else {
  write.table(clean, file.path(path.expand(tsv_dir), paste0(item_encoded, ".tsv")),
              sep = "\t", row.names = FALSE)
  message("Wrote ", tsv_dir, item_encoded, ".tsv")
}
