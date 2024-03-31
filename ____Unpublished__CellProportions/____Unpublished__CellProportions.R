# I. Read the published dataset from the source, and DO NOT pivot wider
## 1. SOURCE
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/")
folder_path <- "./____Unpublished__CellProportions/"

# I. Read the unpublished dataset
library(readxl)
library(dplyr)
library(writexl)

tabledirect <- read_excel(paste0(folder_path,"M1_cross_species_study_FACS_proportions.xlsx"))

#a = tabledirect %>% summarise(across(everything(), mean,na.rm=T), .by = c("Species_full"))
# Summarize "%NeuN+" and "%NeuN-" based on the mean of "Species_full"
summary_data <- tabledirect %>%
  group_by(Species_full) %>%
  summarise(
    "%NeuN+" = mean(`%NeuN+`, na.rm = TRUE),
    "%NeuN-" = mean(`%NeuN-`, na.rm = TRUE)
  )
  
# Write summarized data to Excel file
write_xlsx(summary_data, paste0(folder_path, "CellProportions_summary_data.xlsx"))
