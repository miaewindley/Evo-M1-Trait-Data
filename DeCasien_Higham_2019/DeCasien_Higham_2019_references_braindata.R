## =============================================================================
## DeCasien & Higham 2019 references used by Brain Region Data
## Supplementary Data 1, sheet "Brain Region Data (mm3)" --> reference CSV
## =============================================================================
##
## Purpose
## -----------------------------------------------------------------------------
## Build DeCasien_Higham_2019_references_braindata.csv from the reference codes
## used in the supplementary spreadsheet. The output is an index of source papers
## for the neuroanatomical measurements in the "Brain Region Data (mm3)" sheet.
##
## Current scope
## -----------------------------------------------------------------------------
## This script maps the source reference codes in the spreadsheet to the numbered
## references in DeCasien & Higham (2019). The next provenance step is to add
## paper-specific table/row details for each source, where applicable.
##
## Output format
## -----------------------------------------------------------------------------
## The output keeps the existing two-column format:
##   ref_number, citation
##
## Ranges such as "51-52" are kept as ranges in ref_number because that is how
## DeCasien & Higham coded some multi-paper sources in the spreadsheet. The
## citation column concatenates the citations covered by the range with " | ".
## =============================================================================

options(stringsAsFactors = FALSE)

## ---- paths ------------------------------------------------------------------
script_path <- local({
  argv <- commandArgs(FALSE)
  f <- sub("^--file=", "", argv[grep("^--file=", argv)])
  if (length(f) == 1L && nzchar(f)) return(normalizePath(f))

  sf <- tryCatch(normalizePath(sys.frames()[[1]]$ofile), error = function(e) NULL)
  if (!is.null(sf) && nzchar(sf)) return(sf)

  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- tryCatch(rstudioapi::getSourceEditorContext()$path, error = function(e) "")
    if (!nzchar(p)) p <- tryCatch(rstudioapi::getActiveDocumentContext()$path, error = function(e) "")
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
pdf_file  <- file.path(paper_dir, "DeCasien-2019-Primate mosaic brain evolution r.pdf")

## ---- helpers ----------------------------------------------------------------
normalize_space <- function(x) gsub("\\s+", " ", trimws(x))

extract_references_from_pdf <- function(pdf_file) {
  if (!requireNamespace("pdftools", quietly = TRUE)) {
    stop("Package 'pdftools' is required. Install it with install.packages('pdftools').",
         call. = FALSE)
  }
  if (!file.exists(pdf_file)) {
    stop("Cannot find PDF: ", pdf_file, call. = FALSE)
  }

  txt <- pdftools::pdf_text(pdf_file)

  # DeCasien & Higham's reference list is printed in two columns. If a whole
  # page is parsed as-is, pdftools interleaves the left and right columns and
  # some references get truncated. Split each reference page into visual columns
  # first, then concatenate left column followed by right column.
  page_lines <- function(page_text) strsplit(page_text, "\n", fixed = TRUE)[[1]]

  detect_right_column_start <- function(lines) {
    # Find true reference starts in the right column. Do not use every
    # "number + period" on the page, because body-text citations like
    # "probability26." and values like "1,000." can occur near the
    # column break and make the split too early. A true reference start
    # is followed by an author/title capital letter.
    positions <- unlist(lapply(lines, function(x) {
      m <- gregexpr("(^|\\s{2,})([0-9]{1,3})\\.\\s+[A-Z]", x, perl = TRUE)[[1]]
      if (identical(m, -1L)) return(integer(0))
      
      starts <- attr(m, "capture.start")[, 2]
      starts[starts > 75L]
    }), use.names = FALSE)
    
    if (!length(positions)) return(NA_integer_)
    
    # Use the most common start position. In this PDF it is about 90/91.
    tab <- sort(table(positions), decreasing = TRUE)
    as.integer(names(tab)[1])
  }

  split_two_columns <- function(page_text) {
    lines <- page_lines(page_text)
    right_start <- detect_right_column_start(lines)

    if (is.na(right_start)) {
      return(list(left = lines, right = character(0)))
    }

    left <- vapply(
      lines,
      function(x) substr(x, 1L, min(nchar(x), right_start - 1L)),
      character(1)
    )
    right <- vapply(
      lines,
      function(x) {
        if (nchar(x) >= right_start) substr(x, right_start, nchar(x)) else ""
      },
      character(1)
    )

    list(left = left, right = right)
  }

  # Page 9: references 1-7 are in the lower left column after the References
  # heading; references 8-42 are in the right column. Pages 10-11 continue the
  # same two-column reference-list layout.
  p9 <- split_two_columns(txt[9])
  p9_left <- p9$left
  ref_heading_line <- grep("^References\\s*$", trimws(p9_left))[1]
  if (is.na(ref_heading_line)) {
    stop("Could not find the References heading on PDF page 9.", call. = FALSE)
  }
  p9_left_refs <- p9_left[ref_heading_line:length(p9_left)]

  reference_text <- c(
    p9_left_refs,
    p9$right,
    split_two_columns(txt[10])$left,
    split_two_columns(txt[10])$right,
    split_two_columns(txt[11])$left,
    split_two_columns(txt[11])$right
  )

  section <- paste(reference_text, collapse = "\n")

  # Remove article metadata that follows the references, if it appears in the
  # extracted text.
  section <- sub("(?s)Acknowledgements.*$", "", section, perl = TRUE)
  section <- sub("(?s)Author contributions.*$", "", section, perl = TRUE)
  section <- sub("(?s)Competing interests.*$", "", section, perl = TRUE)
  section <- sub("(?s)Additional information.*$", "", section, perl = TRUE)

  # Normalize common PDF extraction artifacts.
  section <- gsub("\u2010|\u2011|\u2012|\u2013|\u2014", "-", section)
  section <- gsub("\u2212", "-", section)
  section <- gsub("\u00a0", " ", section)
  section <- gsub("\r", "\n", section)

  # Mark reference starts.
  section <- gsub(
    "(^|\\n)\\s*([0-9]{1,3})\\.\\s+",
    "\\1@@REF@@\\2. ",
    section,
    perl = TRUE
  )

  pieces <- strsplit(section, "@@REF@@", fixed = TRUE)[[1]]
  pieces <- pieces[grepl("^[0-9]{1,3}\\.\\s+", pieces)]

  numbers <- sub("^([0-9]{1,3})\\.\\s+.*$", "\\1", pieces)
  cites <- sub("^[0-9]{1,3}\\.\\s+", "", pieces)
  cites <- normalize_space(cites)

  ok <- nzchar(numbers) & nzchar(cites)
  out <- cites[ok]
  names(out) <- numbers[ok]

  # If the same number is accidentally captured twice, keep the longest version.
  out <- tapply(out, names(out), function(x) x[which.max(nchar(x))])
  out <- unlist(out, use.names = TRUE)
  out <- out[order(as.integer(names(out)))]

  out
}

first_number <- function(x) as.integer(sub("^([0-9]+).*", "\\1", x))

expand_ref_code <- function(code) {
  code <- trimws(as.character(code))
  if (grepl("^[0-9]+-[0-9]+$", code)) {
    bounds <- as.integer(strsplit(code, "-", fixed = TRUE)[[1]])
    return(seq.int(bounds[1], bounds[2]))
  }
  as.integer(code)
}

get_reference_codes_from_sheet <- function(path) {
  brain <- readxl::read_excel(
    path,
    sheet = "Brain Region Data (mm3)",
    col_types = "text"
  )

  if (!"References" %in% names(brain)) {
    stop("The sheet 'Brain Region Data (mm3)' does not contain a 'References' column.",
         call. = FALSE)
  }

  refs <- unique(unlist(strsplit(na.omit(brain$References), ",", fixed = TRUE)))
  refs <- trimws(refs)
  refs <- refs[nzchar(refs)]
  refs <- unique(refs)
  refs[order(first_number(refs), grepl("-", refs), refs)]
}

citation_lookup <- extract_references_from_pdf(pdf_file)

## ---- optional PDF check ------------------------------------------------------
## This block is deliberately non-essential. PDF reference text extraction varies
## across systems, so the curated lookup above is the source used for the CSV. The
## check helps catch accidental drift if the PDF changes.
check_pdf_for_required_refs <- function(pdf_file, required_numbers) {
  if (!file.exists(pdf_file) || !requireNamespace("pdftools", quietly = TRUE)) return(invisible(FALSE))

  txt <- pdftools::pdf_text(pdf_file)
  start_page <- grep("\\bReferences\\b", txt)[1]
  if (is.na(start_page)) return(invisible(FALSE))

  section <- paste(txt[start_page:length(txt)], collapse = "\n")
  section <- sub("(?s)Acknowledgements.*$", "", section, perl = TRUE)
  section <- normalize_space(section)

  missing_markers <- required_numbers[!grepl(
    paste0("(^|[^0-9])", required_numbers, "\\."),
    section,
    perl = TRUE
  )]

  if (length(missing_markers)) {
    warning(
      "PDF text check did not find these reference markers; CSV still uses curated lookup: ",
      paste(missing_markers, collapse = ", "),
      call. = FALSE
    )
    return(invisible(FALSE))
  }

  invisible(TRUE)
}

## ---- build and write ---------------------------------------------------------
refs <- get_reference_codes_from_sheet(supp_xlsx)
needed_numbers <- sort(unique(unlist(lapply(refs, expand_ref_code))))

missing <- setdiff(as.character(needed_numbers), names(citation_lookup))
if (length(missing) > 0L) {
  stop(
    "These reference numbers are used in the spreadsheet but are not in citation_lookup: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

check_pdf_for_required_refs <- function(pdf_file, required_numbers) {
  if (!requireNamespace("pdftools", quietly = TRUE)) {
    warning("Package 'pdftools' is not installed; skipping PDF reference check.")
    return(invisible(FALSE))
  }
  if (!file.exists(pdf_file)) {
    warning("PDF not found; skipping PDF reference check: ", pdf_file)
    return(invisible(FALSE))
  }
  
  txt <- pdftools::pdf_text(pdf_file)
  section <- paste(txt, collapse = "\n")
  
  found <- vapply(
    required_numbers,
    function(x) {
      grepl(
        paste0("(^|[^0-9])", x, "\\.\\s+"),
        section,
        perl = TRUE
      )
    },
    logical(1)
  )
  
  missing <- required_numbers[!found]
  
  if (length(missing) > 0L) {
    warning(
      "These required reference numbers were not detected in the PDF text: ",
      paste(missing, collapse = ", ")
    )
    return(invisible(FALSE))
  }
  
  invisible(TRUE)
}
out <- data.frame(
  ref_number = needed_numbers,
  citation   = unname(citation_lookup[as.character(needed_numbers)]),
  check.names = FALSE
)

write.csv(out, output_csv, row.names = FALSE, fileEncoding = "UTF-8")
message("Wrote ", nrow(out), " reference rows to: ", output_csv)
