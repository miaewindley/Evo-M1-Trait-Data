## Compile the comparative BEHAVIOUR dataset — six behavioural measure classes assembled per
## species: vocal repertoire size, digital dexterity, quadrupedal walking gait, locomotor diversity,
## hand preference (handedness), and manipulation complexity.
##
## This folder follows the merge pattern (standardized_term + compile + long/wide), but unlike the
## single-measure merges (__merging_volumes, __merging_gyrification, ...) it spans SEVERAL measure
## classes. Per house rule (__HOWTO_build_a_dataset_file.md §10) different measure classes are never
## pooled into one value: each keeps its own Standardized_Term and its own column. What this folder
## adds is (a) a within-class dedup for the two classes that have >1 source (vocal, dexterity), and
## (b) a combined per-species behaviour_wide table for cross-behaviour correlation.
##
## It composes the project's harmonised trait tables in ____EvoM1_TraitTable/ (each itself built from
## the sources' public TSVs by an EvoM1_read_*.R). The species key mirrors __ShinyApp/build_data.R:
## use `species_sci` where present, else the paper's printed `Species`, cleaned. This keeps the merge
## species identical to what the app correlates on (important: the dexterity table leaves species_sci
## blank on its corticospinal-tract-only rows, whose dexterity values must still be kept via Species).
##
## Domains, sources, dedup rule:
##   Vocalization -> VocalRepertoire (number of vocalization types)
##       Schniter_2026 (updated, primary) + ManyPrimates_2022 (fills gaps). Citation-dependent via
##       McComb & Semple 2005 -> never averaged; prefer Schniter updated. 65 spp.
##   Dexterity -> Dexterity (Heffner & Masterton 1975 1-7 digital-dexterity scale)
##       HeffnerMasterton_1975 (primary) + Iwaniuk_1999 (a re-analysis of the SAME data; identical on
##       all 24 shared species). Citation-dependent -> prefer Heffner & Masterton. 66 spp.
##   Gait -> Duty_Factor, Phase, Gait, Foot_Posture         Wimberly_2021 (single source). 154 spp.
##   Locomotion -> Locomotor_diversity_index, Intermembral_index, Arboreal_terrestrial
##       Granatosky_2018 (single source). 113 spp.
##   Handedness -> Handedness_index_mean, Handedness_strength_mean   Caspar_2022 (single). 38 spp.
##   Manipulation -> Manipulation_complexity, Tool_use, Extractive_foraging  Heldstab_2016. 37 spp.
##
## Outputs: behaviour_long.csv, behaviour_wide.csv, behaviour_source_species_ids.csv, and the merged
## trait table ____EvoM1_TraitTable/behaviour_merged.xlsx for the Shiny app.
suppressWarnings(suppressMessages({library(tidyverse); library(readxl); library(writexl)}))

.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
    return(normalizePath(rstudioapi::getActiveDocumentContext()$path))
  "."
})
setwd(dirname(.sp))
base <- normalizePath(file.path(dirname(.sp), ".."))
TT   <- file.path(base, "____EvoM1_TraitTable")

MS_REF  <- "McComb, K., & Semple, S. (2005). Coevolution of vocal communication and sociality in primates. Biology Letters, 1(4), 381-385."
HM_REF  <- "Heffner, R., & Masterton, B. (1975). Variation in form of the pyramidal tract and its relationship to digital dexterity. Brain, Behavior and Evolution, 12(3), 161-200."
WIM_REF <- "Wimberly, A. N., Slater, G. J., & Granatosky, M. C. (2021). Evolutionary history of quadrupedal walking gaits shows mammalian release from locomotor constraint. Proceedings of the Royal Society B, 288(1957), 20210937."
GRA_REF <- "Granatosky, M. C. (2018). A review of locomotor diversity in mammals with analyses exploring the influence of substrate use, body mass and intermembral index in primates. Journal of Zoology, 306(4), 207-216."
CAS_REF <- "Caspar, K. R., Pallasdies, F., Mader, L., Sartorelli, H., & Begall, S. (2022). The evolution and biological correlates of hand preferences in anthropoid primates. eLife, 11, e77875."
HEL_REF <- "Heldstab, S. A., Kosonen, Z. K., Koski, S. E., Burkart, J. M., van Schaik, C. P., & Isler, K. (2016). Manipulation complexity in primates coevolved with brain size and terrestriality. Scientific Reports, 6, 24528."

SC_ITEM<-"Schniter_Penaherrera-Aguirre_2026_data"; MP_ITEM<-"ManyPrimates__2022_speciespredictors"
HM_ITEM<-"Heffner_Masterton_1975_TableI";          IW_ITEM<-"Iwaniuk_etal_1999_References"
WIM_ITEM<-"Wimberly_etal_2021_mammalgait.txt"
GRA_ITEM<-"Granatosky__2018_TableS1"; CAS_ITEM<-"Caspar_etal_2022_Table1"; HEL_ITEM<-"Heldstab_etal_2016_TableS1"

rd <- function(f) as.data.frame(read_excel(file.path(TT, f), sheet = "Sheet1",
                 col_types = "text", .name_repair = "minimal"), check.names = FALSE)
clean_sp <- function(x) trimws(gsub("\\s+", " ", gsub("_", " ", gsub("\\*", "", x))))
## species key = species_sci where present, else printed Species (mirrors build_data.R)
spkey <- function(d) {
  sci <- if ("species_sci" %in% names(d)) d[["species_sci"]] else rep(NA, nrow(d))
  spp <- if ("Species" %in% names(d)) d[["Species"]] else d[[1]]
  k <- ifelse(!is.na(sci) & nzchar(trimws(sci)) & tolower(trimws(sci)) != "none",
              sci, spp)
  clean_sp(k)
}
istxt <- function(x) !(is.na(x) | trimws(x) == "" | tolower(trimws(x)) %in% c("na","nan","none","-"))

## melt one trait table -> long rows for the given columns/terms
melt_tab <- function(f, dom, term_map, item, team, dg, numeric_only = FALSE) {
  d <- rd(f); d$.k <- spkey(d)
  out <- list()
  for (orig in names(term_map)) {
    if (!(orig %in% names(d))) next
    v <- d[[orig]]; keep <- istxt(v) & nzchar(trimws(d$.k))
    if (numeric_only) keep <- keep & !is.na(suppressWarnings(as.numeric(v)))
    if (!any(keep)) next
    out[[orig]] <- tibble(Species = d$.k[keep], Domain = dom,
                          Standardized_Term = term_map[[orig]], Value = trimws(v[keep]),
                          source = item, team = team, dependency_group = dg)
  }
  bind_rows(out)
}

long <- bind_rows(
  melt_tab("vocal_repertoire_schniter.xlsx","Vocalization",
           c(vocal_repertoire_size_updated="VocalRepertoire"), SC_ITEM,"Schniter_2026","McComb_Semple_2005_lineage",TRUE),
  melt_tab("vocal_repertoire_manyprimates.xlsx","Vocalization",
           c(vocal_repertoire_types="VocalRepertoire"), MP_ITEM,"ManyPrimates_2022","McComb_Semple_2005_lineage",TRUE),
  melt_tab("dexterity_corticospinaltract.xlsx","Dexterity",
           c(`Digital dexterity`="Dexterity"), HM_ITEM,"HeffnerMasterton_1975","HeffnerMasterton_1975_lineage",TRUE),
  melt_tab("corticospinaltract_etc.xlsx","Dexterity",
           c(Dexterity="Dexterity"), IW_ITEM,"Iwaniuk_1999","HeffnerMasterton_1975_lineage",TRUE),
  melt_tab("gait.xlsx","Gait",
           c(Duty_Factor="Duty_Factor",Phase="Phase",Gait="Gait",Foot_Posture="Foot_Posture"), WIM_ITEM,"Wimberly_2021","Wimberly_2021"),
  melt_tab("locomotion.xlsx","Locomotion",
           c(Locomotor_diversity_index="Locomotor_diversity_index",Intermembral_index="Intermembral_index",Arboreal_terrestrial="Arboreal_terrestrial"), GRA_ITEM,"Granatosky_2018","Granatosky_2018"),
  melt_tab("handedness.xlsx","Handedness",
           c(Handedness_index_mean="Handedness_index_mean",Handedness_strength_mean="Handedness_strength_mean"), CAS_ITEM,"Caspar_2022","Caspar_2022"),
  melt_tab("manipulation.xlsx","Manipulation",
           c(Manipulation_complexity="Manipulation_complexity",Tool_use="Tool_use",Extractive_foraging="Extractive_foraging"), HEL_ITEM,"Heldstab_2016","Heldstab_2016")
)
readr::write_csv(long, "behaviour_long.csv")
readr::write_csv(long |> transmute(source, Domain, Standardized_Term, Species, Value),
                 "behaviour_source_species_ids.csv")

## ---- WIDE: within-class dedup; distinct classes/terms side by side ----
val1 <- function(item, term) long |> filter(source == item, Standardized_Term == term) |>
  group_by(Species) |> summarise(v = first(Value), .groups = "drop")
spread_terms <- function(item) long |> filter(source == item) |>
  select(Species, Standardized_Term, Value) |>
  group_by(Species, Standardized_Term) |> summarise(Value = first(Value), .groups = "drop") |>
  pivot_wider(names_from = Standardized_Term, values_from = Value)

vsc<-val1(SC_ITEM,"VocalRepertoire")|>rename(vr_sc=v); vmp<-val1(MP_ITEM,"VocalRepertoire")|>rename(vr_mp=v)
dhm<-val1(HM_ITEM,"Dexterity")|>rename(dx_hm=v);       diw<-val1(IW_ITEM,"Dexterity")|>rename(dx_iw=v)
gw<-spread_terms(WIM_ITEM); lw<-spread_terms(GRA_ITEM); hw<-spread_terms(CAS_ITEM); mw<-spread_terms(HEL_ITEM)

wide <- tibble(Species = sort(unique(long$Species))) |>
  left_join(vsc,by="Species")|>left_join(vmp,by="Species")|>
  left_join(dhm,by="Species")|>left_join(diw,by="Species")|>
  left_join(gw,by="Species")|>left_join(lw,by="Species")|>left_join(hw,by="Species")|>left_join(mw,by="Species")|>
  mutate(
    VocalRepertoire=ifelse(!is.na(vr_sc),vr_sc,vr_mp),
    VocalRepertoire_source=ifelse(!is.na(vr_sc),SC_ITEM,ifelse(!is.na(vr_mp),MP_ITEM,NA)),
    VocalRepertoire_citation_dependency=(!is.na(vr_sc))&(!is.na(vr_mp)),
    Dexterity=ifelse(!is.na(dx_hm),dx_hm,dx_iw),
    Dexterity_source=ifelse(!is.na(dx_hm),HM_ITEM,ifelse(!is.na(dx_iw),IW_ITEM,NA)),
    Dexterity_citation_dependency=(!is.na(dx_hm))&(!is.na(dx_iw)),
    n_domains=(!is.na(VocalRepertoire))+(!is.na(Dexterity))+
      (!is.na(Duty_Factor)|!is.na(Phase)|!is.na(Gait)|!is.na(Foot_Posture))+
      (!is.na(Locomotor_diversity_index)|!is.na(Intermembral_index)|!is.na(Arboreal_terrestrial))+
      (!is.na(Handedness_index_mean)|!is.na(Handedness_strength_mean))+
      (!is.na(Manipulation_complexity)|!is.na(Tool_use)|!is.na(Extractive_foraging))) |>
  select(Species, VocalRepertoire, VocalRepertoire_source, VocalRepertoire_citation_dependency,
         Dexterity, Dexterity_source, Dexterity_citation_dependency,
         Duty_Factor, Phase, Gait, Foot_Posture,
         Locomotor_diversity_index, Intermembral_index, Arboreal_terrestrial,
         Handedness_index_mean, Handedness_strength_mean,
         Manipulation_complexity, Tool_use, Extractive_foraging, n_domains)
readr::write_csv(wide, "behaviour_wide.csv")

## ---- merged trait table for the Shiny app (per-cell _Source) ----
sc <- rd("vocal_repertoire_schniter.xlsx"); sc$.k <- spkey(sc)
mp <- rd("vocal_repertoire_manyprimates.xlsx"); mp$.k <- spkey(mp)
present <- function(...) { a <- list(...); Reduce(`|`, lapply(a, function(x) !is.na(x))) }
merged <- wide |> transmute(
  species_sci = Species, Species,
  VocalRepertoire,
  VocalRepertoire_Source = case_when(
    VocalRepertoire_source==SC_ITEM ~ sc$vocal_repertoire_size_updated_Source[match(Species, sc$.k)],
    VocalRepertoire_source==MP_ITEM ~ mp$vocal_repertoire_types_Source[match(Species, mp$.k)],
    TRUE ~ NA_character_),
  Dexterity, Dexterity_Source = ifelse(!is.na(Dexterity), HM_REF, NA),
  Duty_Factor, Phase, Gait, Foot_Posture,
  Gait_Source = ifelse(present(Duty_Factor,Phase,Gait,Foot_Posture), WIM_REF, NA),
  Locomotor_diversity_index, Intermembral_index, Arboreal_terrestrial,
  Locomotion_Source = ifelse(present(Locomotor_diversity_index,Intermembral_index,Arboreal_terrestrial), GRA_REF, NA),
  Handedness_index_mean, Handedness_strength_mean,
  Handedness_Source = ifelse(present(Handedness_index_mean,Handedness_strength_mean), CAS_REF, NA),
  Manipulation_complexity, Tool_use, Extractive_foraging,
  Manipulation_Source = ifelse(present(Manipulation_complexity,Tool_use,Extractive_foraging), HEL_REF, NA))
merged$VocalRepertoire_Source[is.na(merged$VocalRepertoire_Source) & !is.na(merged$VocalRepertoire)] <- MS_REF
write_xlsx(merged, file.path(TT, "behaviour_merged.xlsx"))

dom_n <- function(cols) sum(apply(wide[cols], 1, function(r) any(!is.na(r))))
message("behaviour: ", nrow(long), " long rows, ", nrow(wide), " species; ",
        sum(!is.na(wide$VocalRepertoire)), " vocal, ", sum(!is.na(wide$Dexterity)), " dexterity, ",
        dom_n(c("Duty_Factor","Phase","Gait","Foot_Posture")), " gait, ",
        dom_n(c("Locomotor_diversity_index","Intermembral_index","Arboreal_terrestrial")), " locomotion, ",
        dom_n(c("Handedness_index_mean","Handedness_strength_mean")), " handedness, ",
        dom_n(c("Manipulation_complexity","Tool_use","Extractive_foraging")), " manipulation; ",
        sum(wide$n_domains >= 2), " in >=2 domains, ", sum(wide$n_domains == 6), " in all six")
