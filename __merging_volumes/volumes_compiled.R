# Merging histologically-derived brain-structure VOLUMES  (two-tier resolution)
# Mirror of ../__merging_cellcounts/cellcounts_compiled.R for the volume data type.
#
# RULE (see README__merging.md):
#  Tier 1 "Stephan_collection" (coauthor group, same Vogt specimens; one evolving
#    dataset): resolve duplicate (species x structure) by MOST RECENT date; flag if a
#    superseding value deviates >50% from the one it replaces. Body/brain weight is the
#    exception -> keep the Stephan 1981 reference (fill gaps only; not averaged).
#  Tier 2 (independent series; different specimens/labs): each is its own team; across
#    teams AVERAGE the surviving values with the Tier-1 result.
#
# Steps: 1 read TSVs  2 standardized terms  3 reshape/convert (Zilles, Bauernfeind,
#        MacLeod, Bush)  4 harmonize species  5 Tier-1 resolve  6 Tier-2 average -> long/wide/flags

library(tidyverse); library(readxl)
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/__merging_volumes")
base <- "~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data"

## 1 Papers: item_name, team, year, species-key token (NA = use species col as-is) ----
papers <- tribble(
  ~item,                               ~team,                ~year, ~token,           ~spcol,

  "Stephan_etal_1981_Table1",          "Stephan_collection", 1981,  "Stephan1981",    "Species_Stephan1981",
  "Stephan_etal_1982_Table1",          "Stephan_collection", 1982,  "Stephan1982",    "Species_Stephan1982",
  "Stephan_etal_1984_Table1",          "Stephan_collection", 1984,  "Stephan1984",    "Species_Stephan1984",
  "Stephan_etal_1987_Table1",          "Stephan_collection", 1987,  "Stephan1987",    "Species_Stephan1987",
  "Frahm_etal_1982_Table2",            "Stephan_collection", 1982,  "Frahm1982",      "Species_Frahm1982",
  "Frahm_etal_1984_Table1",            "Stephan_collection", 1984,  "Frahm_1984",     "Species_Frahm_1984",
  "Frahm_Zilles_1994_Table1",          "Stephan_collection", 1994,  "Frahm1994",      "Species_Frahm1994",
  "Frahm_etal_1997_Table1",            "Stephan_collection", 1997,  "Frahm1997",      "Species_Frahm1997",
  "Frahm_etal_1998_Table1",            "Stephan_collection", 1998,  "Frahm98",        "Species_Frahm98",
  "Baron_etal_1983_Table1",            "Stephan_collection", 1983,  "Baron1983",      "Species_Baron1983",
  "Baron_etal_1987_Table1",            "Stephan_collection", 1987,  "Baron1987",      "Species_Baron1987",
  "Baron_etal_1988_Table1",            "Stephan_collection", 1988,  "Baron1988",      "Species_Baron1988",
  "Baron_etal_1990_Table1",            "Stephan_collection", 1990,  "Baron1990",      "Species_Baron1990",
  "Matano_etal_1985_a_Table1",         "Stephan_collection", 1985,  "Matano1985a",    "Species_Matano1985a",
  "Matano_etal_1985_b_Table1",         "Stephan_collection", 1985,  "Matano1985b",    "Species_Matano1985b",
  "Zilles_Rehkämper_1988_Table12-2",   "Stephan_collection", 1988,  "Zilles1988",     "Species_Zilles1988",
  "deSousa_etal_2010_Table1",          "Zilles",            2010,  "deSousa2010",    "Species_deSousa2010",
  "deSousa_etal_2013_Table1",          "Zilles",            2013,  "deSousa2013",    "Species_deSousa2013",
  "MacLeod_etal_2003_",                "Zilles",            2003,  NA,               "species",
  "Bauernfeind_etal_2013_Table1",      "Zilles",        2013,  "Bauernfeind2013","Species_Bauernfeind2013",
  "Bush_Allman_2003_Table1",           "Bush",               2003,  NA,               "species",
  "Smaers_etal_2011_SupplementaryTable1","Zilles",            2011,  NA,               "species",
  "Ashwell__2020_SupplementaryTable",  "Ashwell",            2020,    "Ashwell2020",    "species",
  "Barger_etal_2007_TABLE1",           "Zilles",             2007,  "Barger2007",     "species"
)
filecodes <- read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
read_item <- function(it) read.table(file.path(base, "__Public/comparative-data",
  paste0(filecodes$"Item encoded"[match(it, filecodes$"Item name")], ".tsv")),
  header = TRUE, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE)

## 2 Standardized terms + 3 reshape/convert -> long (Species, Variable, Value) per paper ----
terms <- read.csv("standardized_term_volumes.csv", check.names = FALSE)
# Laterality guard (suffix-only convention; see README__merging.md "Hemispheres"): every column
# measured from one side only is registered in laterality_known.csv and MUST carry a laterality
# suffix (_unilateral/_left/_right) in its standardized term, so a one-side value can never be
# silently merged/averaged with a both-sides volume. Warns if the registry and term map disagree.
lat_known <- tryCatch(read.csv("laterality_known.csv", stringsAsFactors = FALSE),
                      error = function(e) NULL)
if (!is.null(lat_known) && nrow(lat_known)) {
  chk <- merge(lat_known, terms, by = c("Reference", "Original_Term"), all.x = TRUE)
  bad <- chk[is.na(chk$Standardized_Term) |
               !mapply(function(s, suf) !is.na(s) && grepl(suf, s, fixed = TRUE),
                       chk$Standardized_Term, chk$required_suffix), ]
  if (nrow(bad))
    warning("Laterality guard: ", nrow(bad), " one-side column(s) missing the required suffix -> ",
            paste(sprintf("%s:%s (want %s, got %s)", bad$Reference, bad$Original_Term,
                          bad$required_suffix, bad$Standardized_Term), collapse = "; "))
  else message("Laterality guard OK: ", nrow(lat_known), " one-side column(s) correctly suffixed.")
}
spkey <- read.csv(file.path(base, "_keys/Stephan/species_key.csv"), stringsAsFactors = FALSE)
nrm <- function(x) tolower(trimws(gsub("\\s+"," ", gsub("[._]"," ", x))))
accepted <- function(tok, name) {
  if (is.na(tok)) return(name)
  k <- spkey[spkey$source_publication == tok, ]
  i <- match(nrm(name), nrm(k$variant_name)); ifelse(is.na(i), name, k$accepted_name[i])
}
num <- function(x) suppressWarnings(as.numeric(gsub(",","", as.character(x))))

paper_long <- function(row) {
  it <- row$item; df <- read_item(it); tmap <- terms %>% filter(Reference == it)
  # --- paper-specific reshapes (step 3) ---
  if (it == "Zilles_Rehkämper_1988_Table12-2") {                # structure-rows -> one Pongo row
    z <- df %>% transmute(Species = accepted(row$token, Species_Zilles1988),
                          Variable = tmap$Standardized_Term[match(structure, tmap$Original_Term)],
                          Value = num(volume_mm3)) %>% filter(!is.na(Variable))
    return(z %>% mutate(Source = it, Team = row$team, Year = row$year))
  }
  if (it == "Bauernfeind_etal_2013_Table1") {                   # per-individual -> species means (Pongo merge), mg->g
    df <- df %>% mutate(lab = ifelse(Species_Bauernfeind2013 %in% c("Pongo abelii","Pongo pygmaeus"),
                                     "Pongo pygmaeus and Pongo abelii", Species_Bauernfeind2013))
    meas <- c("granular_L_mm3","dysgranular_L_mm3","agranular_L_mm3","FI_L_mm3","total_insula_L_mm3","brain_volume_mm3","brain_mass_mg","body_mass_g")
    spm <- df %>% group_by(Species_Bauernfeind2013, lab) %>% summarise(across(all_of(meas), ~mean(num(.x), na.rm=TRUE)), .groups="drop")
    df  <- spm %>% group_by(lab) %>% summarise(across(all_of(meas), ~mean(.x, na.rm=TRUE)), .groups="drop") %>%
           mutate(brain_mass_mg = brain_mass_mg/1000) %>% rename(Species_Bauernfeind2013 = lab)
  }
  if (it == "MacLeod_etal_2003_") {                             # per-individual -> species means, cm3->mm3
    meas <- c("cerebellum_volume_cm3","vermis_volume_cm3","hemisphere_volume_cm3","brain_volume_cm3")
    df <- df %>% group_by(species) %>% summarise(across(all_of(meas), ~mean(num(.x)*1000, na.rm=TRUE)), .groups="drop")
  }
  if (it == "Bush_Allman_2003_Table1")                           # cm3 -> mm3
    df <- df %>% mutate(across(ends_with("_cm3"), ~num(.x)*1000))
  if (it == "Smaers_etal_2011_SupplementaryTable1") {            # per-individual frontal -> species means of COMBINED L+R (cm3->mm3)
    fix <- c("Cercopithecus ascianus"="Cercopithecus ascanius","Cercocebus albigena"="Lophocebus albigena",
             "Procolobus badius"="Piliocolobus badius","Lagothrix lagotricha"="Lagothrix lagothricha")
    df <- df %>% mutate(species = ifelse(species %in% names(fix), fix[species], species)) %>%
      group_by(species) %>%
      summarise(frontal_white_total_cm3 = mean(num(frontal_white_total_cm3)*1000, na.rm = TRUE),
                frontal_grey_total_cm3  = mean(num(frontal_grey_total_cm3) *1000, na.rm = TRUE), .groups = "drop")
  }
  if (it == "Stephan_etal_1987_Table1")                          # NTO printed "0" = "not determinable with certainty" (data dictionary), not a true zero -> NA
    df <- df %>% mutate(Nucleus_tractus_olfactorius_mm3 =
            ifelse(num(Nucleus_tractus_olfactorius_mm3) == 0, NA_real_, num(Nucleus_tractus_olfactorius_mm3)))
  if (it == "Barger_etal_2007_TABLE1")                           # per-specimen amygdaloid complex -> species means; cm3 -> mm3
    df <- df %>% group_by(species) %>%
      summarise(AC_total = mean(num(AC_total) * 1000, na.rm = TRUE), .groups = "drop")
  # --- generic wide -> long via standardized terms ---
  keep <- intersect(names(df), tmap$Original_Term)
  df %>% transmute(Species = accepted(row$token, .data[[row$spcol]]),
                   across(all_of(keep), num)) %>%
    pivot_longer(-Species, names_to="orig", values_to="Value") %>%
    filter(!is.na(Value)) %>%
    mutate(Variable = tmap$Standardized_Term[match(orig, tmap$Original_Term)],
           Source = it, Team = row$team, Year = row$year) %>%
    select(Species, Variable, Value, Source, Team, Year)
}
long <- bind_rows(lapply(seq_len(nrow(papers)), function(i) paper_long(papers[i, ])))
write_csv(long, "volumes_unfiltered.csv")
is_mass <- function(v) v %in% c("Body_Mass.g","Brain_Mass.mg")

## 5 Tier-1 resolution (Stephan_collection): most recent; mass -> Stephan 1981; flag deviations ----
flags <- tibble(Species=character(), Variable=character(), flag=character(), detail=character())
t1 <- long %>% filter(Team == "Stephan_collection") %>% arrange(Species, Variable, desc(Year))
t1res <- t1 %>% group_by(Species, Variable) %>% summarise(
  Value = if (is_mass(first(Variable))) {
            s81 <- Value[Source == "Stephan_etal_1981_Table1"]; if (length(s81)) s81[1] else Value[1]
          } else Value[1],
  .groups = "drop")
# flags: newest vs next within Tier-1 (non-mass)
t1 %>% group_by(Species, Variable) %>% filter(n() > 1, !is_mass(first(Variable))) %>%
  summarise(v0=Value[1], s0=Source[1], v1=Value[2], s1=Source[2], .groups="drop") %>%
  filter(abs(v0-v1)/abs(v1) > 0.5) %>%
  transmute(Species, Variable, flag="deviation", detail=paste0(s0,"=",v0," vs ",s1,"=",v1)) -> flags
write_csv(flags, "volumes_flags.csv")

## 6 Tier-2 (each its own team, mean within team) + cross-team average ----
t2 <- long %>% filter(Team != "Stephan_collection") %>%
  group_by(Species, Variable, Team) %>% summarise(Value = mean(Value), .groups="drop")
teamvals <- bind_rows(t1res %>% mutate(Team = "Stephan_collection"), t2)
volumes_long <- teamvals %>% group_by(Species, Variable) %>% summarise(
  Value = if (is_mass(first(Variable)))                       # mass: Stephan reference only (no cross-team avg)
            { sc <- Value[Team=="Stephan_collection"]; if (length(sc)) sc[1] else Value[1] }
          else mean(Value),
  Teams = paste(sort(unique(Team)), collapse="; "), n_teams = n_distinct(Team), .groups="drop") %>%
  arrange(Species, Variable)
write_csv(volumes_long, "volumes_long.csv")
volumes_wide <- volumes_long %>% pivot_wider(id_cols=Species, names_from=Variable, values_from=Value) %>% arrange(Species)
write_csv(volumes_wide, "volumes_wide.csv")
long %>% group_by(Species_Name = Species) %>% summarise(n_sources=n_distinct(Source), Sources=paste(sort(unique(Source)),collapse="; ")) %>%
  write_csv("volumes_source_species_ids.csv")

message(nrow(volumes_wide), " species x ", ncol(volumes_wide)-1, " variables from ", nrow(papers),
        " tables | flags: ", nrow(flags))
