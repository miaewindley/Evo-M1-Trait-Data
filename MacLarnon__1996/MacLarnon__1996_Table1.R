## Install and load necessary libraries
library(dplyr) 
library(readxl)
library(rstudioapi)
library(tidyr)
library(stringr)


#1. Source
#setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/")
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/")


#2. Table 1
## Read direct from xl
folder_path <- "./MacLarnon__1996/" #Note there are two underscores in the file name -- this is because there is a single author.  See __ReadMe.xlsx
tabledirectxl <- read_excel(paste0(folder_path,"MacLarnon__1996_Table1_snapshot.xlsx"))


## Create a new "Order" column 
Order_column <- rep(NA, nrow(tabledirectxl))
tabledirectxl <- cbind(Order = Order_column, tabledirectxl)

## Remove the rows with order names
rows_to_delete <- c(1, 23, 29, 36, 41, 50)
tabledirectxl <- tabledirectxl %>%
  slice(-rows_to_delete)

## Add order names
tabledirectxl$Order[1:21] <- "Primate"
tabledirectxl$Order[22:26] <- "Cetacean"
tabledirectxl$Order[27:32] <- "Rodent"
tabledirectxl$Order[33:36] <- "Lagomorph"
tabledirectxl$Order[37:44] <- "Bird"
tabledirectxl$Order[45] <- "Amphibian"


## Create a new "Subspecies size" column
tabledirectxl <- tabledirectxl %>%
  mutate(`Subspecies size` = NA) %>%
  relocate(`Subspecies size`, .after = `Species`)

## Adding Subspecies Size
tabledirectxl$`Subspecies size`[28:29] <- "Small"
tabledirectxl$`Subspecies size`[30:31] <- "Large"
tabledirectxl$`Subspecies size`[33:34] <- "Small"
tabledirectxl$`Subspecies size`[35:36] <- "Large"

## Removing Subspecies size from Species column 
tabledirectxl[which(tabledirectxl$Species == "Rattus  norvegicus  (small subspecies)"), "Species"] <- "Rattus  norvegicus"
tabledirectxl[which(tabledirectxl$Species == "Rattus  norvegicus  (large subspecies)"), "Species"] <- "Rattus  norvegicus"
tabledirectxl[which(tabledirectxl$Species == "Oryctolagus  cuniculus  (small subspecies)"), "Species"] <- "Oryctolagus  cuniculus"
tabledirectxl[which(tabledirectxl$Species == "Oryctolagus  cuniculus  (large subspecies)"), "Species"] <- "Oryctolagus  cuniculus"


## Delete last row and Ref's column as references will be added directly in the table
tabledirectxl <- tabledirectxl[1:(nrow(tabledirectxl)-1), ]
tabledirectxl <- tabledirectxl %>%
  select(-Refs)


## Dividing Spinal cord length (mm) (Dissection//ΣDCL) into Dissections and ΣDCL

## Preprocess to ensure there are values to split, replace missing with NA
tabledirectxl <- tabledirectxl %>%
  mutate(`Spinal cord length (mm) (Dissection//ΣDCL)` = ifelse(is.na(`Spinal cord length (mm) (Dissection//ΣDCL)`) | 
  `Spinal cord length (mm) (Dissection//ΣDCL)` == "", "NA//NA", `Spinal cord length (mm) (Dissection//ΣDCL)`))
## Identify and inspect rows with unexpected number of pieces
irregular_rows <- tabledirectxl %>%
  filter(str_count(`Spinal cord length (mm) (Dissection//ΣDCL)`, "/") != 1)
print(irregular_rows)
## Separate the "Spinal cord length (mm) (Dissection//ΣDCL)" column
tabledirectxl <- tabledirectxl %>%
  separate(`Spinal cord length (mm) (Dissection//ΣDCL)`, 
           into = c("Spinal cord length (mm): Dissection", "Spinal cord length (mm): ΣDCL"), sep = "/", fill = "right")


## Remove all the — to change to auto NA
tabledirectxl <- tabledirectxl %>%
  mutate(across(everything(),~ ifelse(. %in%c("—"),NA, .)))


## Add Data Source columns
tabledirectxl <- tabledirectxl %>%
  mutate(`Body weight (g): Data Source` = NA) %>%
  relocate(`Body weight (g): Data Source`, .after = `Body weight (g)`)

tabledirectxl <- tabledirectxl %>%
  mutate(`Body weight (mg): Data Source` = NA) %>%
  relocate(`Body weight (mg): Data Source`, .after = `Body weight (mg)`)

tabledirectxl <- tabledirectxl %>%
  mutate(`Spinal cord weight (mg): Data Source` = NA) %>%
  relocate(`Spinal cord weight (mg): Data Source`, .after = `Spinal cord weight (mg)`)

tabledirectxl <- tabledirectxl %>%
  mutate(`Spinal cord length (mm): Dissection: Data Source` = NA) %>%
  relocate(`Spinal cord length (mm): Dissection: Data Source`, .after = `Spinal cord length (mm): Dissection`)

tabledirectxl <- tabledirectxl %>%
  mutate(`Spinal cord length (mm): ΣDCL: Data Source` = NA) %>%
  relocate(`Spinal cord length (mm): ΣDCL: Data Source`, .after = `Spinal cord length (mm): ΣDCL`)

## Add Data Source and References 
tabledirectxl$`Body weight (g): Data Source`[c(1, 3, 4, 7, 12, 14:21)] <- "Martin & MacLarnon (unpublished data collection)"
tabledirectxl$`Body weight (g): Data Source`[c(5, 6, 8, 9, 10, 13)] <- "Present study (Formol–saline subset)"
tabledirectxl$`Body weight (g): Data Source`[11] <- "Hopf & Claussen  (1971)"
tabledirectxl$`Body weight (g): Data Source`[c(27:29, 37:45)] <- "Krompecher & Lipák  (1966)"
tabledirectxl$`Body weight (g): Data Source`[22:26] <- "Ridgway et al. (1966)"
tabledirectxl$`Body weight (g): Data Source`[30:31] <- "Donaldson & Hatai (1911)"
tabledirectxl$`Body weight (g): Data Source`[32] <- "Latimer (1950)"
tabledirectxl$`Body weight (g): Data Source`[33:34] <- "Latimer & Sawin (1955)"
tabledirectxl$`Body weight (g): Data Source`[35:36] <- "Latimer & Sawin (1957)"
tabledirectxl$`Body weight (g): Data Source`[2] <- "Nayak (1933)"

tabledirectxl$`Body weight (mg): Data Source`[c(3:5, 7:9, 13:19, 21)] <- "Martin & MacLarnon (unpublished data collection)"
tabledirectxl$`Body weight (mg): Data Source`[c(6, 10, 20)] <- "Present study (Formol–saline subset)"
tabledirectxl$`Body weight (mg): Data Source`[11:12] <- "Hopf & Claussen  (1971)"
tabledirectxl$`Body weight (mg): Data Source`[c(27:29, 37:45)] <- "Krompecher & Lipák  (1966)"
tabledirectxl$`Body weight (mg): Data Source`[22:26] <- "Ridgway et al. (1966)"
tabledirectxl$`Body weight (mg): Data Source`[30:31] <- "Donaldson & Hatai (1911)"
tabledirectxl$`Body weight (mg): Data Source`[32] <- "Latimer (1950)"
tabledirectxl$`Body weight (mg): Data Source`[33:34] <- "Latimer & Sawin (1955)"
tabledirectxl$`Body weight (mg): Data Source`[35:36] <- "Latimer & Sawin (1957)"

tabledirectxl$`Spinal cord weight (mg): Data Source`[c(3, 5:10, 13, 20)] <- "Present study (Formol–saline subset)"
tabledirectxl$`Spinal cord weight (mg): Data Source`[c(4, 14, 15)] <- "Present study (Non-Formol–saline subset)"
tabledirectxl$`Spinal cord weight (mg): Data Source`[c(11, 12, 16:19)] <- "Hopf & Claussen  (1971)"
tabledirectxl$`Spinal cord weight (mg): Data Source`[c(27:29, 37:45)] <- "Krompecher & Lipák  (1966)"
tabledirectxl$`Spinal cord weight (mg): Data Source`[22:26] <- "Ridgway et al. (1966)"
tabledirectxl$`Spinal cord weight (mg): Data Source`[30:31] <- "Donaldson & Hatai (1911)"
tabledirectxl$`Spinal cord weight (mg): Data Source`[32] <- "Latimer (1950)"
tabledirectxl$`Spinal cord weight (mg): Data Source`[33:34] <- "Latimer & Sawin (1955)"
tabledirectxl$`Spinal cord weight (mg): Data Source`[35:36] <- "Latimer & Sawin (1957)"
tabledirectxl$`Spinal cord weight (mg): Data Source`[21] <- "Present study (Non-Formol–saline subset); Krompecher & Lipák (1966); Ravenel (1877)"

tabledirectxl$`Spinal cord length (mm): Dissection: Data Source`[c(3, 5:9, 13, 20)] <- "Present study (Formol–saline subset)"
tabledirectxl$`Spinal cord length (mm): Dissection: Data Source`[c(4, 14, 15)] <- "Present study (Non-Formol–saline subset)"
tabledirectxl$`Spinal cord length (mm): Dissection: Data Source`[32] <- "Latimer (1950)"
tabledirectxl$`Spinal cord length (mm): Dissection: Data Source`[21] <- "Present study (Non-Formol–saline subset); Krompecher & Lipák (1966); Ravenel (1877)"

tabledirectxl$`Spinal cord length (mm): ΣDCL: Data Source`[c(3, 5:10, 13, 20)] <- "Present study (Formol–saline subset)"
tabledirectxl$`Spinal cord length (mm): ΣDCL: Data Source`[c(4, 14, 15)] <- "Present study (Non-Formol–saline subset)"
tabledirectxl$`Spinal cord length (mm): ΣDCL: Data Source`[32] <- "Latimer (1950)"
tabledirectxl$`Spinal cord length (mm): ΣDCL: Data Source`[1:2] <- "Nayak (1933)"
tabledirectxl$`Spinal cord length (mm): ΣDCL: Data Source`[21] <- "Present study (Non-Formol–saline subset); Krompecher & Lipák (1966); Ravenel (1877)"


## Seperate Male and Female Column for Spinal cord length (mm): Dissection
## Duplicate row 21 insert it after row 21 
tabledirectxl <- tabledirectxl %>%
  add_row(.after = 21, !!!tabledirectxl[21, ])

## Create a new "Spinal cord length (mm): Dissection: Sex (specified)" column
tabledirectxl <- tabledirectxl %>%
  mutate(`Spinal cord length (mm): Dissection: Sex (specified)` = NA) %>%
  relocate(`Spinal cord length (mm): Dissection: Sex (specified)`, .after = `Body weight (mg): Data Source`)

## Adding the Sex and removing it from Spinal cord length (mm): Dissection column
tabledirectxl$`Spinal cord length (mm): Dissection: Sex (specified)`[21] <- "M"
tabledirectxl$`Spinal cord length (mm): Dissection: Sex (specified)`[22] <- "F"
tabledirectxl$`Spinal cord length (mm): Dissection: Sex (specified)`[33] <- "M"
tabledirectxl$`Spinal cord length (mm): Dissection`[21] <- "448"
tabledirectxl$`Spinal cord length (mm): Dissection`[22] <- "413"
tabledirectxl$`Spinal cord length (mm): Dissection`[33] <- "162.98"


## Remove asterisks from all columns
tabledirectxl$"Body weight (g)" <- gsub("\\*", "", tabledirectxl$"Body weight (g)")
tabledirectxl$"Body weight (mg)" <- gsub("\\*", "", tabledirectxl$"Body weight (mg)")

## Remove space(a character) from in between numbers
tabledirectxl$"Body weight (g)" <- gsub(" ", "", tabledirectxl$"Body weight (g)")
tabledirectxl$"Body weight (mg)" <- gsub(" ", "", tabledirectxl$"Body weight (mg)")
tabledirectxl$"Spinal cord weight (mg)" <- gsub(" ", "", tabledirectxl$"Spinal cord weight (mg)")
tabledirectxl$"Spinal cord length (mm): Dissection" <- gsub(" ", "", tabledirectxl$"Spinal cord length (mm): Dissection")
tabledirectxl$"Spinal cord length (mm): ΣDCL" <- gsub(" ", "", tabledirectxl$"Spinal cord length (mm): ΣDCL")

## Remove ·(a character) from in between numbers
tabledirectxl$"Body weight (g)" <- gsub("·", ".", tabledirectxl$"Body weight (g)")
tabledirectxl$"Body weight (mg)" <- gsub("·", ".", tabledirectxl$"Body weight (mg)")
tabledirectxl$"Spinal cord weight (mg)" <- gsub("·", ".", tabledirectxl$"Spinal cord weight (mg)")
tabledirectxl$"Spinal cord length (mm): Dissection" <- gsub("·", ".", tabledirectxl$"Spinal cord length (mm): Dissection")
tabledirectxl$"Spinal cord length (mm): ΣDCL" <- gsub("·", ".", tabledirectxl$"Spinal cord length (mm): ΣDCL")


## Convert columns from chr to numerical
tabledirectxl$`Body weight (g)`<- as.numeric(tabledirectxl$`Body weight (g)`)
tabledirectxl$`Body weight (mg)` <- as.numeric(tabledirectxl$`Body weight (mg)`)
tabledirectxl$`Spinal cord weight (mg)` <- as.numeric(tabledirectxl$`Spinal cord weight (mg)`)
tabledirectxl$`Spinal cord length (mm): Dissection` <- as.numeric(tabledirectxl$`Spinal cord length (mm): Dissection`)
tabledirectxl$`Spinal cord length (mm): ΣDCL` <- as.numeric(tabledirectxl$`Spinal cord length (mm): ΣDCL`)


#3. Save

## Finalize dataframe (UPDATE!!!)
final.dataframe <- tabledirectxl

## Get Item name: Get Path of the current script, Extract the file name, Remove the ".R" extension
item_name <- gsub("\\.R$", "", basename(rstudioapi::getActiveDocumentContext()$path))

## Get Item encoded
filecodes <- read_excel("./__ReadMe.xlsx", sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]

## Save dataframe to a CSV file
write.csv(final.dataframe, file = paste0(folder_path, item_name, ".csv"), row.names = FALSE)

## Save dataframe to a TSV file in the online database
tsv_file_path <- "./__Public/comparative-data/"
write.table(final.dataframe, file = paste0(tsv_file_path, item_encoded, ".tsv"), sep = "\t", row.names = FALSE)



######ExtraCodes#######

## Replacing reference numbers with citations
# tabledirectxl[which(tabledirectxl$Refs == "1"), "Refs"] <- "Present study (FS  subset)"
# tabledirectxl[which(tabledirectxl$Refs == "2"), "Refs"] <- "Present study (non-FS  subset)"
# tabledirectxl[which(tabledirectxl$Refs == "3"), "Refs"] <- "Hopf & Claussen  (1971)"
# tabledirectxl[which(tabledirectxl$Refs == "4"), "Refs"] <- "Krompecher & Lipák  (1966)"
# tabledirectxl[which(tabledirectxl$Refs == "5"), "Refs"] <- "Ridgway et al. (1966)"
# tabledirectxl[which(tabledirectxl$Refs == "6"), "Refs"] <- "Donaldson & Hatai (1911)"
# tabledirectxl[which(tabledirectxl$Refs == "7"), "Refs"] <- "Latimer (1950)"
# tabledirectxl[which(tabledirectxl$Refs == "8"), "Refs"] <- "Latimer & Sawin (1955)"
# tabledirectxl[which(tabledirectxl$Refs == "9"), "Refs"] <- "Latimer & Sawin (1957)"
# tabledirectxl[which(tabledirectxl$Refs == "10"), "Refs"] <- "Ravenel (1877)"
# tabledirectxl[which(tabledirectxl$Refs == "11"), "Refs"] <- "Nayak (1933)"
# tabledirectxl$Refs[21] <- "Present study (non-FS subset); Krompecher & Lipák (1966); Ravenel (1877)"

## Change the header name of the 'Refs' column
# names(tabledirectxl)[which(names(tabledirectxl) == "Refs")] <- "References (all data for a species come from a single source except where indicated)"

## Citing the * in Body weight (g) column
# tabledirectxl$`Body weight (g)`[1] <- "2800 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[3] <- "1165 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[4] <- "287 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[7] <- "805 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[12] <- "3469 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[14] <- "3610 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[15] <- "21 750 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[16] <- "17 950 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[17] <- "10 000 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[18] <- "19 410 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[19] <- "11 690 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[20] <- "34 100 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (g)`[21] <- "60 000 *Martin & MacLarnon (unpublished data collection)"

## Citing the * in Body weight (mg) column
# tabledirectxl$`Body weight (mg)`[3] <- "10 650 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[4] <- "7980 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[5] <- "9250 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[7] <- "24 700 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[8] <- "86 200 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[9] <- "60 800 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[13] <- "110 500 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[14] <- "62 100 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[15] <- "180 900 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[16] <- "165 500 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[17] <- "147 300 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[18] <- "121 000 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[19] <- "114 500 *Martin & MacLarnon (unpublished data collection)"
# tabledirectxl$`Body weight (mg)`[21] <- "1 273 700 *Martin & MacLarnon (unpublished data collection)"


## Remove asterisks from all columns
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "2800*"), "Body weight (g)"] <- "2800"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "1165*"), "Body weight (g)"] <- "1165"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "287*"), "Body weight (g)"] <- "287"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "805*"), "Body weight (g)"] <- "805"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "3469*"), "Body weight (g)"] <- "3469"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "3610*"), "Body weight (g)"] <- "3610"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "21 750*"), "Body weight (g)"] <- "21 750"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "17 950*"), "Body weight (g)"] <- "17 950"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "10 000*"), "Body weight (g)"] <- "10 000"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "19 410*"), "Body weight (g)"] <- "19 410"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "11 690*"), "Body weight (g)"] <- "11 690"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "34 100*"), "Body weight (g)"] <- "34 100"
# tabledirectxl[which(tabledirectxl$"Body weight (g)" == "60 000*"), "Body weight (g)"] <- "60 000"
# 
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "10 650*"), "Body weight (mg)"] <- "10 650"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "7980*"), "Body weight (mg)"] <- "7980"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "9250*"), "Body weight (mg)"] <- "9250"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "24 700*"), "Body weight (mg)"] <- "24 700"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "86 200*"), "Body weight (mg)"] <- "86 200"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "60 800*"), "Body weight (mg)"] <- "60 800"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "110 500*"), "Body weight (mg)"] <- "110 500"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "62 100*"), "Body weight (mg)"] <- "62 100"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "180 900*"), "Body weight (mg)"] <- "180 900"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "165 500*"), "Body weight (mg)"] <- "165 500"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "147 300*"), "Body weight (mg)"] <- "147 300"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "121 000*"), "Body weight (mg)"] <- "121 000"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "114 500*"), "Body weight (mg)"] <- "114 500"
# tabledirectxl[which(tabledirectxl$"Body weight (mg)" == "1 273 700*"), "Body weight (mg)"] <- "1 273 700"
