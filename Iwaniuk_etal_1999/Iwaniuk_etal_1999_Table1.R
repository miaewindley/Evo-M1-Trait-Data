## 1. Source
#setwd("C:/Users/MILONI/OneDrive - University of Bath/Research Schemes/Allen Institue/Evo-M1-Trait-Data/")
#setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/")
##B's wd
setwd("C:/Users/Rigby/OneDrive - University of Bath/Evo-M1-Trait-Data/Iwaniuk_etal_1999")

## 2. Table 2
#1. Read direct from xl
library(readxl)
folder_path <- "./Iwaniuk_etal_1999/"
tabledirectxl <-
  read_excel(paste0(folder_path, "Iwaniuk_etal_1999_Table1_snapshot.xlsx"))

#2. Change header name of column 1 and 2
colnames(tabledirectxl)[1] <- "Species Generic Name"
colnames(tabledirectxl)[2] <- "Species Scientific Name"

# Save
# Finalize dataframe (UPDATE!!!)
final.dataframe <- tabledirectxl

# Get Item name: Get Path of the current script, Extract the file name, Remove the ".R" extension
library(rstudioapi)
item_name <-
  gsub("\\.R$",
       "",
       basename(rstudioapi::getActiveDocumentContext()$path))

# Get Item encoded
library(readxl)
filecodes <- read_excel("./__ReadMe.xlsx", sheet = "Sheet1")
item_encoded <-
  filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]

# Save dataframe to a CSV file
write.csv(
  final.dataframe,
  file = paste0(folder_path, item_name, ".csv"),
  row.names = FALSE
)

# Save dataframe to a TSV file in the online database
tsv_file_path <- "./__Public/comparative-data/"
write.table(
  final.dataframe,
  file = paste0(tsv_file_path, item_encoded, ".tsv"),
  sep = "\t",
  row.names = FALSE
)