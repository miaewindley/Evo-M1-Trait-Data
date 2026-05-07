## 0. Paths -------------------------------------------------------
library(rstudioapi)

script_path   <- rstudioapi::getActiveDocumentContext()$path
paper_dir     <- dirname(script_path)
dataset_root  <- dirname(paper_dir)
table_name    <- tools::file_path_sans_ext(basename(script_path))

# outputs
snapshot_xlsx  <- file.path(paper_dir, paste0(table_name, "_snapshot.xlsx"))
final_csv     <- file.path(paper_dir, paste0(table_name, ".csv"))
readme_xlsx   <- file.path(dataset_root, "__ReadMe.xlsx")
public_tsv_dir<- file.path(dataset_root, "__Public", "comparative-data")

library(readxl)
library(dplyr)
library(stringr)
library(tidyr)

# ------------------------------------------------------------
# 1) Read raw sheet (no headers)
# ------------------------------------------------------------

raw <- read_excel(snapshot_xlsx, sheet = 1, col_names = FALSE) |>
  mutate(across(everything(), as.character))
            
# ------------------------------------------------------------
# 2) Build column names 
# ------------------------------------------------------------

# IGNORE rows 1–2 (table title)
raw2 <- raw[-c(1, 2), ]

# Extract header rows as character vectors
h1 <- as.character(raw2[1, ])
h2 <- as.character(raw2[2, ])
h1[h1 == "NA"] <- NA
h2[h2 == "NA"] <- NA
h1 <- stringr::str_trim(h1)
h2 <- stringr::str_trim(h2)

# Fill to the right in row 1 to get main column names
for (i in seq_along(h1)) {
  if (is.na(h1[i]) && i > 1) {
    h1[i] <- h1[i - 1]
  }
}

# Combine header rows to create final column names
col_names <- mapply(
  function(a, b) {
    paste(c(a, b)[!is.na(c(a, b)) & c(a, b) != ""], collapse = " ")
  },
  h1, h2,
  USE.NAMES = FALSE
)

# ------------------------------------------------------------
# 3) Remove header rows and assign column names
# ------------------------------------------------------------

df0 <- raw2[-c(1:2), ]
colnames(df0) <- col_names

# ------------------------------------------------------------
# 4) Detect indentation
# ------------------------------------------------------------

# First, handle exception

# find the row index of the global average
i <- which(df0$Region == "Cerebral cortex (global average)")
stopifnot(length(i) == 1)

# create a new non-indented category row
new_row <- df0[i, ]
new_row[] <- NA
new_row$Region <- "Cerebral cortex"

# build df1 with the inserted row and indented original row
df1 <- bind_rows(
  df0[1:(i - 1), ],
  new_row,
  df0[i, ] |> mutate(Region = paste0("    ", Region)),
  df0[(i + 1):nrow(df0), ]
)


df2 <- df1 |>
  mutate(
    raw_region = Region,
    indented = raw_region != str_trim(raw_region),
    region = str_squish(raw_region)
  )

# ------------------------------------------------------------
# 5) Create categories from subheader rows
# ------------------------------------------------------------

df3 <- df2 |>
  mutate(
    category = if_else(!indented, region, NA_character_)
  ) |>
  fill(category, .direction = "down")

# ------------------------------------------------------------
# 6) Remove the category subheader rows themselves (they are not indented) and helper columns
# ------------------------------------------------------------

df4 <- df3 |>
  filter(indented) |>                 # remove subheaders
  mutate(
    Region = str_squish(raw_region)    # NOW it is safe to unindent
  ) |>
  select(category, everything()) |>  # put category first
  select(-raw_region, -indented, -region)    # drop helper columns

# ------------------------------------------------------------
# 7) Coerce numeric columns
# ------------------------------------------------------------

is_numeric <- function(x) {
  str_detect(
    x,
    "^[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?$"
  )
}

# Remove dagger symbols (†) from P before coercion
df_numeric <- df4 |>
  mutate(P = str_remove_all(P, "†"))

# Replace Unicode minus signs (U+2212) with ASCII hyphens for coercion
df_numeric <- df_numeric |>
  mutate(
    `Left minus right hemisphere Difference` =
      str_replace_all(
        `Left minus right hemisphere Difference`,
        "\u2212", "-"
      )
  )

df_numeric <- df_numeric |>
  mutate(across(
    -c(category, Region),
    ~ {
      x <- str_trim(.x)
      ifelse(is_numeric(x), as.numeric(x), x)
    }
  ))

# ------------------------------------------------------------
# 8) Save (LOCAL CSV + PUBLIC TSV)
# ------------------------------------------------------------

final.dataframe <- df_numeric

# Item encoded lookup uses table_name (script filename)
filecodes <- read_excel(file.path(dataset_root, "__ReadMe.xlsx"), sheet = "Sheet1")
item_encoded <- filecodes$`Item encoded`[match(table_name, filecodes$`Item name`)]

# Local output next to the paper
write.csv(final.dataframe, final_csv, row.names = FALSE)

# Public TSV output
dir.create(public_tsv_dir, recursive = TRUE, showWarnings = FALSE)
write.table(final.dataframe,
            file = file.path(public_tsv_dir, paste0(item_encoded, ".tsv")),
            sep = "\t", row.names = FALSE)



