setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo-M1-Trait-Data/")
folder_path <- "./DosSantos_etal_2020/"

library(readxl)

DosSantos_etal_2020_Table1 <- read_csv(paste0(folder_path,"DosSantos_etal_2020_Table1.csv"))

# 2. Read the unpublished dataset
tabledirectxl <- read_excel(paste0(folder_path,"2020-PublishedDataMammalsMicroglia - cópia.xlsx"))


tabledirect_reduced <- tabledirectxl[-c(1,4:7,12)]
a = tabledirect_reduced %>% summarise(across(everything(), mean,na.rm=T), .by = c("Animal Latin Name", "Structure"))
b <- as.data.frame(a)

# Whole Brain C (number of cells)
unpublished <- data.frame(b$`Number cells 2H`[b$Structure == c("Whole brain")], b$`Animal Latin Name`[b$Structure == c("Whole brain")])
paper <- data.frame(DosSantos_etal_2020_Table1$Br_C, DosSantos_etal_2020_Table1$"Species name")
colnames(paper)=c("Br_C", "Species")
colnames(unpublished)=c("Br_C_U", "Species")
merged_df<- merge(paper,unpublished, all = T)
## the different ones
paper[!paper$Br_C %in% unpublished$Br_C_U, ]

# Whole Brain I/N (microglia per neurons)
unpublished <- data.frame(b$`Iba1/N`[b$Structure == c("Whole brain")], b$`Animal Latin Name`[b$Structure == c("Whole brain")])
paper <- data.frame(DosSantos_etal_2020_Table1$`Br_I/N`, DosSantos_etal_2020_Table1$"Species name")
colnames(paper)=c("Br_I/N", "Species")
colnames(unpublished)=c("Br_I/N_U", "Species")
merged_df<- merge(paper,unpublished, all = T)
## the different ones after rounding up
paper[!paper$`Br_I/N` %in% round(unpublished$`Br_I/N_U`,digits=3), ]

## repeat for I/N for all other structures Cerebral Cortex etc.
## PROBABLY only keep I/N from that paper -- check I/N is OK
