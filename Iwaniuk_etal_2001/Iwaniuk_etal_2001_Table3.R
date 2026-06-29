## Load Libraries

## ---- paths: self-contained (Rscript or RStudio; full repo or lone folder) ----
.sp <- local({
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)             # Rscript file.R
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getSourceEditorContext()$path                    # RStudio: Source
    if (!nzchar(p)) p <- rstudioapi::getActiveDocumentContext()$path  # RStudio: Run
    if (nzchar(p)) return(normalizePath(p))
  }
  stop("Run with Rscript file.R, or open in RStudio and click Source (save first).", call. = FALSE)
})
folder <- paper_dir <- dirname(.sp)                                   # this paper's folder
item_name <- table_name <- tools::file_path_sans_ext(basename(.sp))  # = file name (matches __ReadMe.xlsx)
base <- dataset_root <- local({                                      # repo root; NA if run as a lone folder
  d <- folder
  while (dirname(d) != d && !file.exists(file.path(d, "__ReadMe.xlsx"))) d <- dirname(d)
  if (file.exists(file.path(d, "__ReadMe.xlsx"))) d else NA_character_
})
setwd(folder)

library(readxl)
library(rstudioapi)

#1. Source
setwd(paste0(base, "/"))
setwd(paste0(base, "/"))

#2. Table 3

## 1. Read direct from xl
folder_path <- paste0(folder, "/")
tabledirectxl <- read_excel(paste0(folder_path,"Iwaniuk_etal_2001_Table3_snapshot.xlsx"))

## 2. Adding Family 
tabledirectxl$Family[3] <- "Burramyidae"
tabledirectxl$Family[5:15] <- "Dasyuridae"
tabledirectxl$Family[17] <- "Didelphidae"
tabledirectxl$Family[19:43] <- "Macropodidae"
tabledirectxl$Family[46:47] <- "Peramelidae"
tabledirectxl$Family[49:53] <- "Petauridae"
tabledirectxl$Family[58] <- "Vombatidae"

## 3. Minimum and maximum play frequency 
## Add columns for minimum and maximum play frequency to the right of "Play frequency" column
tabledirectxl <- cbind(tabledirectxl[, 1:which(names(tabledirectxl) == "Play frequency")], 
                       "Play frequency Minimum" = NA, 
                       "Play frequency Maximum" = NA,
                       tabledirectxl[, (which(names(tabledirectxl) == "Play frequency") + 1):ncol(tabledirectxl)])

## Copy values from "Play frequency" column to "Play frequency Minimum" and "Play frequency Maximum" columns for rows 1 to 58
tabledirectxl[1:58, "Play frequency Minimum"] <- tabledirectxl[1:58, "Play frequency"]
tabledirectxl[1:58, "Play frequency Maximum"] <- tabledirectxl[1:58, "Play frequency"]

## Replacing 2/3C
tabledirectxl$`Play frequency Minimum`[c(17, 18, 21, 22, 39)] <- "2"
tabledirectxl$`Play frequency Maximum`[c(17, 18, 21, 22, 39)] <- "3"

## 4. Convert columns to numerical
tabledirectxl$`Play frequency Minimum` <- as.numeric(tabledirectxl$`Play frequency Minimum`)
tabledirectxl$`Play frequency Maximum` <- as.numeric(tabledirectxl$`Play frequency Maximum`)

#3. Save
## 1. Finalize dataframe (UPDATE!!!)
final.dataframe <- tabledirectxl

## 2. Get Item name: Get Path of the current script, Extract the file name, Remove the ".R" extension
item_name <- gsub("\\.R$", "", basename(.sp))

## 3. Get Item encoded
filecodes <- read_excel(file.path(base, "__ReadMe.xlsx"), sheet = "Sheet1")
item_encoded <- filecodes$"Item encoded"[match(item_name, filecodes$"Item name")]

## 4. Save dataframe to a CSV file
write.csv(final.dataframe, file = paste0(folder_path, item_name, ".csv"), row.names = FALSE)

## 5. Save dataframe to a TSV file in the online database
tsv_file_path <- paste0(file.path(base, "__Public", "comparative-data"), "/")
write.table(final.dataframe, file = paste0(tsv_file_path, item_encoded, ".tsv"), sep = "\t", row.names = FALSE)

