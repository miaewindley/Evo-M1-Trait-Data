## Bush EC, Allman JM (2004). Three-dimensional structure and evolution of primate
## primary visual cortex. Anat Rec A 281A(1):1088-1094. TABLE 1.
##
## Build step only: frozen snapshot -> clean analysis CSV -> DOI-coded public TSV.
## Species are harmonised to the project key (printed name kept as species_as_published).
## QA against the compiled/de Sousa copies lives separately in comparison/ (run those
## scripts on their own; this build does not perform the comparison).
##
## Input : Bush_Allman_2004_b_TABLE1_snapshot.csv  (species + V1G,LGN,V1surf,Hmerid,Wb,NeoW,NeoG)
## Output: Bush_Allman_2004_b_TABLE1.csv           one row per species (21)
##         <Item encoded>.tsv in __Public/comparative-data/  (named from __ReadMe.xlsx)

options(scipen = 999)
script_path <- normalizePath(rstudioapi::getActiveDocumentContext()$path)
folder <- dirname(script_path)
base   <- dirname(folder)
setwd(folder)

## ---- read the frozen snapshot (verbatim headers) ----
snap <- read.csv("Bush_Allman_2004_b_TABLE1_snapshot.csv",
                 check.names = FALSE, stringsAsFactors = FALSE,
                 na.strings = c("", "NA", "n.a.", "-", "--"))

## ---- harmonise species to the project key (printed name preserved) ----
key    <- read.csv(file.path(base, "_keys/Allman/species_key.csv"), stringsAsFactors = FALSE)
lookup <- c(setNames(key$accepted_name, tolower(key$variant_name)),
            setNames(key$accepted_name, tolower(key$accepted_name)))
harm   <- function(s) { s <- trimws(s); v <- lookup[tolower(s)]
                        if (is.na(v)) s else unname(v) }
num    <- function(x) suppressWarnings(as.numeric(gsub(",", "", trimws(as.character(x)))))

## ---- clean (units kept as printed: volumes cm3, V1 surface cm2, meridian mm) ----
clean <- data.frame(
  species                = vapply(snap$species, harm, character(1), USE.NAMES = FALSE),
  species_as_published   = trimws(snap$species),
  V1_grey_cm3            = num(snap$V1G),
  LGN_cm3                = num(snap$LGN),
  V1_surface_cm2         = num(snap$V1surf),
  horizontal_meridian_mm = num(snap$Hmerid),
  whole_brain_cm3        = num(snap$Wb),
  neocortex_white_cm3    = num(snap$NeoW),
  neocortex_grey_cm3     = num(snap$NeoG),
  source                 = "Bush_Allman_2004_b",
  stringsAsFactors = FALSE
)

## ---- local CSV: use this R script's filename ----

script_path <- rstudioapi::getActiveDocumentContext()$path

if (!nzchar(script_path)) {
  stop("Save the R script before running it.")
}

script_path <- normalizePath(script_path)

folder    <- dirname(script_path)
base      <- dirname(folder)
item_name <- tools::file_path_sans_ext(basename(script_path))

csv_file <- file.path(folder, paste0(item_name, ".csv"))

write.csv(clean, csv_file, row.names = FALSE)

message(item_name, ": ", nrow(clean), " rows written to ", basename(csv_file))


## ---- public TSV: look up the DOI/PMID code from __ReadMe.xlsx ----

tsv_dir <- file.path(base, "__Public", "comparative-data")

filecodes <- readxl::read_excel(
  file.path(base, "__ReadMe.xlsx"),
  sheet = "Sheet1"
)

item_encoded <- filecodes$`Item encoded`[
  match(item_name, filecodes$`Item name`)
]

if (is.na(item_encoded) || !nzchar(item_encoded)) {
  warning("No 'Item encoded' for '", item_name, "' in __ReadMe.xlsx; TSV skipped.")
  
} else if (!dir.exists(path.expand(tsv_dir))) {
  warning("Shared folder not found: ", tsv_dir, "; TSV skipped.")
  
} else {
  tsv_file <- file.path(path.expand(tsv_dir), paste0(item_encoded, ".tsv"))
  
  write.table(
    clean,
    tsv_file,
    sep = "\t",
    row.names = FALSE
  )
  
  message("Wrote ", tsv_file)
}