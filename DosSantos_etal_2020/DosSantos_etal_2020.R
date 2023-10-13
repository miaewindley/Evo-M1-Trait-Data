#SOURCE
setwd("~/Library/CloudStorage/OneDrive-AllenInstitute/Species/Evo M1 Trait Data/DosSantos_etal_2020")

# This extracts most of the table, but the Loxodota africana row at the end is missing!
# Load the tabulizer library and rJava
library(rJava)
library(tabulizer)
library(tabulizerjars)

# Define the PDF file path
pdf_file <- "https://www.jneurosci.org/content/jneuro/40/24/4622.full.pdf"
# Use extract_tables to get all tables on the specified page
tables1 <- extract_tables(pdf_file,pages = c(4:6))

# Remove the first row
tables1[[1]] <- tables1[[1]][-1, ]
tables1[[2]] <- tables1[[2]][-1, ]
tables1[[3]] <- tables1[[3]][-1, ]

# Use the now first row as column names for the first matrix in tables1
colnames(tables1[[1]]) <- tables1[[1]][1, ]
colnames(tables1[[2]]) <- tables1[[2]][1, ]
colnames(tables1[[3]]) <- tables1[[3]][1, ]

# Delete the now first row 
tables1[[1]] <- tables1[[1]][-1, ]
tables1[[2]] <- tables1[[2]][-1, ]
tables1[[3]] <- tables1[[3]][-1, ]

# Convert the matrices into data frames
df1 <- as.data.frame(tables1[[1]])
df2 <- as.data.frame(tables1[[2]])
df3 <- as.data.frame(tables1[[3]])

# Shift column names in df3 for columns 6-9
colnames(df3)[6:9] <- colnames(df3)[5:8]


# Load the dplyr package if not already loaded
library(dplyr)

# Delete columns with exact names "V5", "V7", and "V9" from df1
df1 <- df1 %>% select(-matches("^V5$|^V7$|^V9$"))
df2 <- df2 %>% select(-matches("^V5$|^V7$|^V9$"))
df3 <- df3 %>% select(-matches("^V5$|^V7$|^V5.1$")) #this one is different
                          
# Stack df1, df2, and df3 into a new combined data frame
combined_df <- bind_rows(df1, df2, df3)

# Deal with empty row where the name was split among two rows
# Combine the text from rows 155 and 156 into row 155
combined_df[155,] <- paste(combined_df[155,], combined_df[156,], sep = " ")
# Delete row 156
combined_df <- combined_df[-156, ]


