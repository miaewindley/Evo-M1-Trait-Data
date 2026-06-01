# Baron_etal_1983_Table1_compare_to_Baron_1983_csv.R
# Purpose: Compare the faithful snapshot of Baron et al. 1983 Table 1 against
#          an existing draft/analysis CSV (e.g., Baron_1983.csv).
# Input 1: Baron_etal_1983_Table1_snapshot.csv (faithful PDF snapshot)
# Input 2: Baron_1983.csv (user-provided comparison table)
# Output : comparison detail and mismatch CSVs.

snapshot_file <- "Baron_etal_1983_Table1_snapshot.csv"
comparison_file <- "Baron_1983.csv"
output_detail <- "Baron_etal_1983_Table1_comparison_report_from_R.csv"
output_mismatches <- "Baron_etal_1983_Table1_comparison_mismatches_from_R.csv"

read_csv_any <- function(path, header = TRUE) {
  tryCatch(
    read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, header = header,
             na.strings = c(""), fill = TRUE, fileEncoding = "UTF-8-BOM"),
    error = function(e) {
      read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, header = header,
               na.strings = c(""), fill = TRUE, fileEncoding = "latin1")
    }
  )
}

read_snapshot <- function(path) {
  raw <- read_csv_any(path, header = FALSE)
  header <- as.character(unlist(raw[2, ]))
  dat <- raw[-c(1,2), ]
  names(dat) <- header
  dat
}

normalize_code <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x[is.na(x)] <- ""
  out <- gsub("[^0-9]", "", x)
  out[out == ""] <- NA_character_
  suppressWarnings(as.character(as.integer(out)))
}

parse_number <- function(x) {
  x <- as.character(x)
  x <- gsub(",", "", x)
  x <- trimws(x)
  x[x %in% c("", "-", "NA", "n.a.")] <- NA_character_
  pattern <- "[-+]?[0-9]+([.][0-9]+)?"
  has_number <- !is.na(x) & grepl(pattern, x)
  out <- rep(NA_real_, length(x))
  out[has_number] <- suppressWarnings(as.numeric(sub(paste0(".*?(", pattern, ").*"), "\\1", x[has_number])))
  out
}

normalize_species_label <- function(x) {
  x <- as.character(x)
  x <- gsub("[0-9]+", "", x)       # drop footnote digits
  x <- gsub("\\.", "", x)          # drop periods used for abbreviations in the snapshot
  x <- gsub("\\s+", " ", x)
  trimws(tolower(x))
}

snapshot <- read_snapshot(snapshot_file)

# Carry forward the current section heading, but only keep rows with four-digit species codes.
snapshot$taxonomic_group_snapshot <- NA_character_
current_group <- NA_character_
for (i in seq_len(nrow(snapshot))) {
  code_i <- snapshot[["code number of species"]][i]
  species_i <- snapshot[["species name"]][i]
  if (!is.na(code_i) && grepl("^[0-9]{4}$", code_i)) {
    snapshot$taxonomic_group_snapshot[i] <- current_group
  } else if ((is.na(code_i) || code_i == "") && !is.na(species_i) && species_i != "Means") {
    current_group <- species_i
  }
}

snap_species <- snapshot[!is.na(snapshot[["code number of species"]]) & grepl("^[0-9]{4}$", snapshot[["code number of species"]]), ]
snap_species$code_norm <- normalize_code(snap_species[["code number of species"]])
snap_species$n_snapshot_numeric <- parse_number(snap_species[["n"]])
snap_species$volume_snapshot_numeric <- parse_number(snap_species[["volume in mm3"]])
snap_species$species_snapshot_norm <- normalize_species_label(snap_species[["species name"]])

comparison <- read_csv_any(comparison_file, header = TRUE)
comparison <- comparison[!grepl("^AAAA_", comparison$Species), ]
comparison <- comparison[!is.na(comparison$Bulbus_olfactorius_1983) & comparison$Bulbus_olfactorius_1983 != "", ]
comparison$code_norm <- normalize_code(comparison$code_Baron1983)
comparison$n_csv_numeric <- parse_number(comparison$Number_of_individuals_Bulbus_olfactorius)
comparison$volume_csv_numeric <- parse_number(comparison$Bulbus_olfactorius_1983)
comparison$species_csv_baron_norm <- normalize_species_label(comparison$Species_Baron1983)

merged <- merge(
  snap_species,
  comparison,
  by = "code_norm",
  all = TRUE,
  suffixes = c("_snapshot", "_csv")
)

merged$code_match <- !is.na(merged[["code number of species"]]) & !is.na(merged$code_Baron1983)
merged$n_match <- merged$n_snapshot_numeric == merged$n_csv_numeric
merged$volume_match <- merged$volume_snapshot_numeric == merged$volume_csv_numeric
merged$species_label_match_after_light_normalization <- merged$species_snapshot_norm == merged$species_csv_baron_norm
merged$status <- ifelse(is.na(merged[["code number of species"]]), "csv_value_row_missing_from_snapshot",
                 ifelse(is.na(merged$code_Baron1983), "snapshot_row_missing_from_csv", "matched_by_code"))

out <- data.frame(
  status = merged$status,
  code_norm = merged$code_norm,
  code_snapshot = merged[["code number of species"]],
  code_csv = merged$code_Baron1983,
  species_snapshot = merged[["species name"]],
  species_csv_baron1983 = merged$Species_Baron1983,
  species_csv_updated = merged$Species,
  taxonomic_group_snapshot = merged$taxonomic_group_snapshot,
  n_snapshot = merged$n,
  n_snapshot_numeric = merged$n_snapshot_numeric,
  n_csv = merged$Number_of_individuals_Bulbus_olfactorius,
  n_csv_numeric = merged$n_csv_numeric,
  volume_snapshot = merged[["volume in mm3"]],
  volume_snapshot_numeric = merged$volume_snapshot_numeric,
  volume_csv = merged$Bulbus_olfactorius_1983,
  volume_csv_numeric = merged$volume_csv_numeric,
  code_match = merged$code_match,
  n_match = merged$n_match,
  volume_match = merged$volume_match,
  species_label_match_after_light_normalization = merged$species_label_match_after_light_normalization,
  stringsAsFactors = FALSE
)

write.csv(out, output_detail, row.names = FALSE)
mismatches <- out[out$status != "matched_by_code" | !out$code_match | !out$n_match | !out$volume_match, ]
write.csv(mismatches, output_mismatches, row.names = FALSE)

message("Wrote ", output_detail)
message("Wrote ", output_mismatches)
message("Rows in snapshot species table: ", nrow(snap_species))
message("Rows in comparison CSV with values: ", nrow(comparison))
message("Mismatches on code/n/volume: ", nrow(mismatches))
