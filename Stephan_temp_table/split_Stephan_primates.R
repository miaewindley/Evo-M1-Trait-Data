library(readxl)
library(dplyr)
library(stringr)
library(writexl)

# ------------------------------------------------------------
# 1. Read data and metadata
# ------------------------------------------------------------

primates <- read_excel("Stephan_primates.xlsx")

metadata <- read_excel(
  "Stephan_primates metadata.xlsx",
  sheet = "Stephan_NHprimates metadata",
  col_names = FALSE
)

# ------------------------------------------------------------
# 2. Parse metadata: variable -> source
# ------------------------------------------------------------
# The metadata sheet alternates roughly as:
#   variable name
#   code / notes
#   source citation

var_to_source <- list()
current_var <- NA_character_

for (i in seq_len(nrow(metadata))) {
  cell <- as.character(metadata[[1]][i])
  
  # If this matches a column name in the data, treat as variable
  if (!is.na(cell) && cell %in% names(primates)) {
    current_var <- cell
  }
  
  # If we have a variable and the line looks like a citation, record it
  else if (!is.na(current_var) &&
           str_detect(cell, "et al|Bauernfeind|Zilles|Smaers")) {
    var_to_source[[current_var]] <- cell
    current_var <- NA_character_
  }
}

var_to_source_df <- tibble(
  variable = names(var_to_source),
  source   = unlist(var_to_source, use.names = FALSE)
)

# ------------------------------------------------------------
# 3. Group variables by source
# ------------------------------------------------------------

source_to_vars <- var_to_source_df %>%
  group_by(source) %>%
  summarise(vars = list(variable), .groups = "drop")

# Identifier columns to keep everywhere
id_cols <- names(primates) %>%
  keep(~ str_starts(tolower(.x), "species") | str_detect(.x, "Code"))

# ------------------------------------------------------------
# 4. Create one sheet per source
# ------------------------------------------------------------

sheets <- list()

for (i in seq_len(nrow(source_to_vars))) {
  src  <- source_to_vars$source[i]
  vars <- source_to_vars$vars[[i]]
  
  cols <- unique(c(id_cols, vars))
  
  sheets[[str_sub(src, 1, 31)]] <- primates %>%
    select(all_of(cols))
}

# ------------------------------------------------------------
# 5. Write Excel file
# ------------------------------------------------------------

write_xlsx(
  sheets,
  path = "Stephan_primates_by_source.xlsx"
)