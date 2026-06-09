## Semendeferi K, Lu A, Schenker N, Damasio H (2002), Nat Neurosci 5(3):272-276
## "Humans and great apes share a large frontal cortex." Table 1: relative size of frontal cortex.
## NB: values are PERCENT of cerebral cortex (not absolute mm3). Snapshot -> clean.
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/Semendeferi_etal_2002")
options(scipen = 999)
raw <- read.csv("Semendeferi_etal_2002_Table1_snapshot.csv", check.names = FALSE, stringsAsFactors = FALSE)
binom <- c(Human="Homo sapiens", Chimpanzee="Pan troglodytes", Bonobo="Pan paniscus",
           Gorilla="Gorilla gorilla", Orangutan="Pongo pygmaeus", Gibbon="Hylobates lar",
           Macaque="Macaca sp.", Cebus="Cebus sp.")
ps <- raw[["Present study volume %"]]
parse_mean <- function(x) if (grepl(" and ", x)) round(mean(as.numeric(strsplit(x," and ")[[1]])),3) else as.numeric(sub("^([0-9.]+).*$","\\1",x))
parse_sd   <- function(x) { m <- regmatches(x, regexpr("[0-9.]+(?=\\))", x, perl=TRUE)); if (length(m)) as.numeric(m) else NA_real_ }
opt <- function(x) suppressWarnings(as.numeric(ifelse(x=="NA","",x)))
clean <- data.frame(species = unname(binom[raw$Species]),
                    frontal_cortex_pct_of_cortex_volume = vapply(ps, parse_mean, numeric(1)),
                    sd = vapply(ps, parse_sd, numeric(1)),
                    brodmann1909_surface_pct = opt(raw[["Brodmann (1909) surface %"]]),
                    blinkov_glezer1965_surface_pct = opt(raw[["Blinkov & Glezer (1965) surface %"]]),
                    note = ifelse(grepl(" and ", ps), "n=2 (two specimens)", ""),
                    source = "Semendeferi_etal_2002", stringsAsFactors = FALSE)
write.csv(clean, "Semendeferi_etal_2002_Table1.csv", row.names = FALSE)
