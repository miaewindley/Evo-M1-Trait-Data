## =============================================================================
## DeCasien & Higham 2019 references used by Brain Region Data
## Supplementary Data 1, sheet "Brain Region Data (mm3)" --> reference CSV
## =============================================================================
##
## Purpose
## -----------------------------------------------------------------------------
## Build DeCasien_Higham_2019_references_braindata.csv from the reference numbers
## used in the supplementary spreadsheet. This file is an index of source papers
## for the neuroanatomical measurements in the "Brain Region Data (mm3)" sheet.
##
## Current scope
## -----------------------------------------------------------------------------
## This script only maps the source reference numbers to the numbered references
## in DeCasien & Higham (2019). The next provenance step is to add paper-specific
## table/row details for each source, where applicable.
##
## Golden rule
## -----------------------------------------------------------------------------
## The output keeps the existing two-column format:
##   ref_number, citation
##
## The output filename is derived from this script filename.
## =============================================================================

options(stringsAsFactors = FALSE)

script_path <- local({
  argv <- commandArgs(FALSE)
  f <- sub("^--file=", "", argv[grep("^--file=", argv)])
  if (length(f) == 1L && nzchar(f)) return(normalizePath(f))

  sf <- tryCatch(normalizePath(sys.frames()[[1]]$ofile), error = function(e) NULL)
  if (!is.null(sf) && nzchar(sf)) return(sf)

  if (requireNamespace("rstudioapi", quietly = TRUE)) {
    p <- tryCatch(rstudioapi::getActiveDocumentContext()$path, error = function(e) "")
    if (nzchar(p)) return(normalizePath(p))
  }

  file.path(getwd(), "DeCasien_Higham_2019_references_braindata.R")
})

paper_dir  <- dirname(script_path)
output_csv <- file.path(
  paper_dir,
  paste0(tools::file_path_sans_ext(basename(script_path)), ".csv")
)

supp_xlsx <- file.path(paper_dir, "41559_2019_969_MOESM3_ESM.xlsx")
if (!file.exists(supp_xlsx)) {
  stop("Cannot find supplementary spreadsheet: ", supp_xlsx, call. = FALSE)
}

if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Package 'readxl' is required. Install it with install.packages('readxl').", call. = FALSE)
}

brain <- readxl::read_excel(
  supp_xlsx,
  sheet = "Brain Region Data (mm3)",
  col_types = "text"
)

if (!"References" %in% names(brain)) {
  stop("The sheet 'Brain Region Data (mm3)' does not contain a 'References' column.", call. = FALSE)
}

## The References column can contain comma-separated reference groups such as
## "24,51-52". Keep ranges as ranges because that is how DeCasien & Higham coded
## some multi-paper sources in the spreadsheet.
refs <- unique(unlist(strsplit(na.omit(brain$References), ",", fixed = TRUE)))
refs <- trimws(refs)
refs <- refs[nzchar(refs)]
refs <- unique(refs)

first_number <- function(x) as.integer(sub("^([0-9]+).*", "\\1", x))
refs <- refs[order(first_number(refs), grepl("-", refs), refs)]

## Numbered references from DeCasien & Higham (2019), References section.
## For ranged source codes (for example, 54-55), this two-column index keeps the
## same convention as the existing CSV: the displayed citation is the first paper
## in the range. The detailed table-level provenance can be added in a later file.
citation_lookup <- c(
  "24" = "Stephan, H., Frahm, H. & Baron, G. New and revised data on volumes of brain structures in insectivores and primates. Folia Primatol. 35, 1–29 (1981).",
  "34" = "Frahm, H. D., Stephan, H. & Baron, G. Comparison of brain structure volumes in insectivora and primates. V. Area striata (AS). J. Hirnforsch. 25, 537–557 (1984).",
  "43" = "Bauernfeind, A. L. et al. A volumetric comparison of the insular cortex and its subregions in primates. J. Hum. Evol. 64, 263–279 (2013).",
  "51" = "Stephan, H., Bauchot, R., & Andy, O. J. in The Primate Brain (eds Noback, C. R. & Montagna, W.) 289–297 (Appleton-Century-Crofts, 1970).",
  "51-52" = "Stephan, H., Bauchot, R., & Andy, O. J. in The Primate Brain (eds Noback, C. R. & Montagna, W.) 289–297 (Appleton-Century-Crofts, 1970).",
  "53" = "Sherwood, C. C. et al. Evolution of the brainstem orofacial motor system in primates: a comparative study of trigeminal, facial, and hypoglossal nuclei. J. Hum. Evol. 48, 45–84 (2005).",
  "54" = "Bush, E. C. & Allman, J. M. Three-dimensional structure and evolution of primate primary visual cortex. Anat. Rec. A 281, 1088–1094 (2004).",
  "54-55" = "Bush, E. C. & Allman, J. M. Three-dimensional structure and evolution of primate primary visual cortex. Anat. Rec. A 281, 1088–1094 (2004).",
  "56" = "Barger, N., Stefanacci, L. & Semendeferi, K. A comparative volumetric analysis of the amygdaloid complex and basolateral division in the human and ape brain. Am. J. Phys. Anthropol. 134, 392–403 (2007",
  "56-57" = "Barger, N., Stefanacci, L. & Semendeferi, K. A comparative volumetric analysis of the amygdaloid complex and basolateral division in the human and ape brain. Am. J. Phys. Anthropol. 134, 392–403 (2007",
  "58" = "Stimpson, C. D. et al. Differential serotonergic innervation of the amygdala in bonobos and chimpanzees. Soc. Cogn. Affect. Neurosci. 11, 413–422 (2015).",
  "59" = "Zilles, K. & Rehkämper, G. in Orang-utan Biology (ed. Schwartz, J. H.) 157–176 (Oxford Univ. Press, 1988).",
  "60" = "De Sousa, A. A. et al. Hominoid visual brain structure volumes and the position of the lunate sulcus. J. Hum. Evol. 58, 281–292 (2010).",
  "61" = "MacLeod, C. E., Zilles, K., Schleicher, A., Rilling, J. K. & Gibson, K. R. Expansion of the neocerebellum in Hominoidea. J. Hum. Evol. 44, 401–429 (2003).",
  "62" = "Rilling, J. K. & Insel, T. R. Evolution of the cerebellum in primates: differences in relative volume among monkeys, apes and humans. Brain Behav. Evol. 52, 308–314 (1998).",
  "62-63" = "Rilling, J. K. & Insel, T. R. Evolution of the cerebellum in primates: differences in relative volume among monkeys, apes and humans. Brain Behav. Evol. 52, 308–314 (1998).",
  "64" = "Sherwood, C. C. et al. Brain structure variation in great apes, with attention to the mountain gorilla (Gorilla beringei beringei). Am. J. Primatol. 63, 149–164 (2004).",
  "65" = "Barks, S. K. et al. Brain organization of gorillas reflects species differences in ecology. Am. J. Phys. Anthropol. 156, 252–262 (2015)."
)

missing <- setdiff(refs, names(citation_lookup))
if (length(missing) > 0L) {
  stop(
    "These reference codes are used in the spreadsheet but are not in citation_lookup: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

out <- data.frame(
  ref_number = refs,
  citation   = unname(citation_lookup[refs]),
  check.names = FALSE
)

if (file.exists(output_csv)) {
  old <- tryCatch(read.csv(output_csv, check.names = FALSE), error = function(e) NULL)
  if (!is.null(old) && !identical(old, out)) {
    warning(
      "Existing CSV differs from regenerated output. Overwriting: ", output_csv,
      call. = FALSE
    )
  }
}

write.csv(out, output_csv, row.names = FALSE, fileEncoding = "UTF-8")
