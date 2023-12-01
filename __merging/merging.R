#source
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo M1 Trait Data/__merging")

# Get the names of all files in the folder
file_names <- list.files("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo M1 Trait Data/__merging")

# Print the file names
print(file_names)

#cellcounts <- read.csv("cellcountsterms.csv", stringsAsFactors = FALSE)
DosSantos_etal_2017_TableS1 <- read.csv("dossantos_etal_2017_TableS1_terms.csv", stringsAsFactors = FALSE)
DosSantos_etal_2020_Table1 <- read.csv("DosSantos_etal_2020_Table1_terms.csv", stringsAsFactors = FALSE)
HerculanoHouzel_etal_2015_Table1 <- read.csv("HerculanoHouzel_etal_2015_Table1_terms.csv", stringsAsFactors = FALSE)
HerculanoHouzel_etal_2015_Table2 <- read.csv("HerculanoHouzel_etal_2015_Table2_terms.csv", stringsAsFactors = FALSE)
HerculanoHouzel_etal_2015_Table3 <- read.csv("HerculanoHouzel_etal_2015_Table3_terms.csv", stringsAsFactors = FALSE)
HerculanoHouzel_etal_2015_Table4 <- read.csv("HerculanoHouzel_etal_2015_Table4_terms.csv", stringsAsFactors = FALSE)
HerculanoHouzel_etal_2015_Table5 <- read.csv("HerculanoHouzel_etal_2015_Table5_terms.csv", stringsAsFactors = FALSE)
HerculanoHouzel_etal_2020_Table1 <- read.csv("HerculanoHouzel_etal_2020_Table1_terms.csv", stringsAsFactors = FALSE)
HerculanoHouzel_etal_2020_Table2 <- read.csv("HerculanoHouzel_etal_2020_Table2_terms.csv", stringsAsFactors = FALSE)
JardimMesseder_etal_2017_Table1 <- read.csv("JardimMesseder_etal_2017_Table1_terms.csv", stringsAsFactors = FALSE)
Kverkova_etal_2018_TableS1 <- read.csv("Kverkova_etal_2018_TableS1_terms.csv", stringsAsFactors = FALSE)
Kverkova_etal_2018_TableS5 <- read.csv("Kverkova_etal_2018_TableS5_terms.csv", stringsAsFactors = FALSE)

# Merge all dataframes into one
mergerd_one <- rbind(
  cellcounts,
  DosSantos_etal_2017_TableS1,
  DosSantos_etal_2020_Table1,
  HerculanoHouzel_etal_2015_Table1,
  HerculanoHouzel_etal_2015_Table2,
  HerculanoHouzel_etal_2015_Table3,
  HerculanoHouzel_etal_2015_Table4,
  HerculanoHouzel_etal_2015_Table5,
  HerculanoHouzel_etal_2020_Table1,
  HerculanoHouzel_etal_2020_Table2,
  JardimMesseder_etal_2017_Table1,
  Kverkova_etal_2018_TableS1,
  Kverkova_etal_2018_TableS5
)
