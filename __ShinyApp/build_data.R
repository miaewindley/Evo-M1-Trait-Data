#!/usr/bin/env Rscript
# =============================================================================
# build_data.R  --  regenerate the Shiny app's derived data from the canonical
# repo files. data/ holds only:
#   * evom1_traits_long.csv  (DERIVED: melted from ____EvoM1_TraitTable/*.xlsx)
#   * source_manifest.csv    (DERIVED: source-table catalogue + citations)
#   * volumes_long.csv, cellcounts_long.csv  (small fallback copies)
#
# The app reads everything from GitHub at runtime; these files are the fallback
# plus the two things that don't exist anywhere else. Re-run whenever the merge
# or trait tables change, then commit + push:
#
#     Rscript __ShinyApp/build_data.R
#
# Requires: readxl  (install.packages("readxl"))
# =============================================================================

suppressWarnings(suppressMessages(library(readxl)))

# ---- locate repo root (parent of this script's folder) ----------------------
args     <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grep("^--file=", args)])
app_dir  <- if (length(file_arg)) dirname(normalizePath(file_arg)) else getwd()
repo     <- normalizePath(file.path(app_dir, ".."))
out      <- file.path(app_dir, "data")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
message("repo: ", repo)
message("out:  ", out)

trim <- function(x) trimws(as.character(x))

# ---- 1. fallback copies of the two compiled long tables ---------------------
file.copy(file.path(repo, "__merging_volumes", "volumes_long.csv"),
          file.path(out, "volumes_long.csv"), overwrite = TRUE)
file.copy(file.path(repo, "__merging_cellcounts", "cellcounts_long.csv"),
          file.path(out, "cellcounts_long.csv"), overwrite = TRUE)

# ---- 2. melt the EvoM1 trait tables -> evom1_traits_long.csv -----------------
TT <- file.path(repo, "____EvoM1_TraitTable")
trait_files <- c(
  "dexterity_corticospinaltract.xlsx" = "Dexterity & corticospinal tract",
  "corticospinaltract_etc.xlsx"       = "Corticospinal tract & ecology",
  "glia_gyrification.xlsx"            = "Glia, gyrification & life history",
  "interlaminar_astrocytes.xlsx"      = "Interlaminar astrocytes"
)
id_cols  <- c("species_sci", "Species", "Animal", "Species Generic Name")
suffixes <- c("_Source", " Source", "_Ref", " Ref", "_ref", " ref")
is_src   <- function(c) any(endsWith(c, suffixes))
base_of  <- function(c) { for (s in suffixes) if (endsWith(c, s))
                            return(trimws(substr(c, 1, nchar(c) - nchar(s)))); c }

trait_rows <- vector("list", 0L)
for (i in seq_along(trait_files)) {
  fn <- names(trait_files)[i]; label <- unname(trait_files[i])
  d  <- as.data.frame(read_excel(file.path(TT, fn), sheet = "Sheet1",
                                 col_types = "text", .name_repair = "minimal"),
                      stringsAsFactors = FALSE, check.names = FALSE)
  cols <- names(d)
  src_map <- list()
  for (cn in cols) if (nzchar(cn) && is_src(cn)) src_map[[base_of(cn)]] <- cn
  sp_col <- if ("Species" %in% cols) "Species" else cols[1]
  for (r in seq_len(nrow(d))) {
    sp <- d[[sp_col]][r]
    if (is.na(sp) || !nzchar(trim(sp)) || tolower(trim(sp)) == "none") next
    sp <- trim(sp)
    for (cn in cols) {
      if (!nzchar(cn) || cn %in% id_cols || is_src(cn)) next
      v <- d[[cn]][r]
      if (is.na(v)) next
      vs <- trim(v)
      if (!nzchar(vs) || tolower(vs) %in% c("na", "nan", "none", "-")) next
      src <- label
      sc  <- src_map[[cn]]
      if (!is.null(sc)) {
        sv <- d[[sc]][r]
        if (!is.na(sv) && nzchar(trim(sv))) src <- trim(sv)
      }
      trait_rows[[length(trait_rows) + 1L]] <-
        data.frame(Species = sp, Variable = cn, Value = vs, Source = src,
                   stringsAsFactors = FALSE)
    }
  }
}
traits <- unique(do.call(rbind, trait_rows))
write.csv(traits, file.path(out, "evom1_traits_long.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
message("evom1 traits rows: ", nrow(traits))

# ---- 3. index the public source tables (served from GitHub, not copied) -----
pub  <- file.path(repo, "__Public", "comparative-data")
tsvs <- sort(list.files(pub, pattern = "\\.tsv$"))
mds  <- list.files(pub, pattern = "\\.ReadMe\\.md$")
message("source tables indexed (served from GitHub): ", length(tsvs))

# ---- 4. build source_manifest.csv (filenames + citations from __ReadMe.xlsx) -
readme <- as.data.frame(read_excel(file.path(repo, "__ReadMe.xlsx"),
                                   sheet = "Sheet1", col_types = "text",
                                   .name_repair = "minimal"),
                        stringsAsFactors = FALSE, check.names = FALSE)
enc_col  <- "Item encoded"
cit_col  <- "Citation (APA 7th-Annotated)"
auth_col <- "1st Author"; year_col <- "year"
readme[[enc_col]] <- as.character(readme[[enc_col]])
by_enc   <- readme[!is.na(readme[[enc_col]]) & nzchar(readme[[enc_col]]), ]
enc_pref <- sub("_.*$", "", by_enc[[enc_col]])

rows <- lapply(tsvs, function(fn) {
  base <- sub("\\.tsv$", "", fn)
  if (grepl("_", base)) {
    label     <- sub("^.*_([^_]*)$", "\\1", base)
    ident_enc <- sub("^(.*)_[^_]*$", "\\1", base)
  } else { label <- ""; ident_enc <- base }
  ident <- utils::URLdecode(ident_enc)

  url <- ""; kind <- "Other"
  if (startsWith(ident, "10.")) {
    url <- paste0("https://doi.org/", ident); kind <- "DOI"
  } else if (grepl("^PMID", ident, ignore.case = TRUE)) {
    url  <- paste0("https://pubmed.ncbi.nlm.nih.gov/", gsub("[^0-9]", "", ident), "/")
    kind <- "PubMed"
  } else if (grepl("^UMI", ident, ignore.case = TRUE)) {
    kind <- "Dissertation (ProQuest)"
  }

  hit <- which(by_enc[[enc_col]] == base)
  if (!length(hit)) hit <- which(enc_pref == ident_enc)
  cit <- auth <- yr <- ""
  if (length(hit)) {
    h <- hit[1]
    cit  <- trim(by_enc[[cit_col]][h]);  if (is.na(cit)  || cit  == "NA") cit  <- ""
    auth <- trim(by_enc[[auth_col]][h]); if (is.na(auth) || auth == "NA") auth <- ""
    yr   <- trim(by_enc[[year_col]][h]); if (is.na(yr)   || yr   == "NA") yr   <- ""
  }
  short <- if (nzchar(auth) && nzchar(yr)) sprintf("%s et al. (%s)", auth, yr)
           else if (nzchar(auth)) auth
           else if (nzchar(cit)) substr(strsplit(cit, ".", fixed = TRUE)[[1]][1], 1, 60)
           else ident

  rm <- ""
  for (cand in c(paste0(base, ".ReadMe.md"), paste0(ident_enc, ".ReadMe.md")))
    if (cand %in% mds) { rm <- cand; break }

  tab <- read.delim(file.path(pub, fn), stringsAsFactors = FALSE,
                    check.names = FALSE, quote = "\"", colClasses = "character")
  data.frame(file = fn, identifier = ident, id_type = kind, table_label = label,
             url = url, readme = rm, n_rows = nrow(tab), n_cols = ncol(tab),
             columns = paste(names(tab), collapse = "; "),
             citation = cit, citation_short = short,
             first_author = auth, year = yr,
             stringsAsFactors = FALSE)
})
manifest <- do.call(rbind, rows)
write.csv(manifest, file.path(out, "source_manifest.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
message("manifest rows: ", nrow(manifest),
        " | with citation: ", sum(nzchar(manifest$citation)))
message("DONE -> ", out)
