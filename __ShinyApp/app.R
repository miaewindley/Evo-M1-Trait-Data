# =============================================================================
# Evo-M1-Trait-Data explorer  -- public Shiny app
# Two views:
#   1. Compiled database  : harmonized long tables (brain-structure volumes +
#                            cell counts), searchable / filterable / plottable.
#   2. Source tables      : the per-publication TSVs in __Public/comparative-data,
#                            each linked to its DOI / PubMed / ISBN source.
#
# Self-contained: all data lives in ./data and is bundled on deploy.
# Deploy with:  rsconnect::deployApp("__ShinyApp")   (see DEPLOY.md)
# =============================================================================

library(shiny)
library(bslib)
library(DT)
library(ggplot2)

# ---- Data source ------------------------------------------------------------
# Primary source is the public GitHub repo (single source of truth); a small
# local copy in ./data acts as a fallback if GitHub is briefly unreachable.
# Override the branch/base with the EVOM1_GH_BASE env var if needed.

GH_BASE <- Sys.getenv(
  "EVOM1_GH_BASE",
  "https://raw.githubusercontent.com/AleAliSousa/Evo-M1-Trait-Data/main/"
)
data_dir <- "data"
options(timeout = max(60, getOption("timeout")))  # allow slow raw.github reads

# percent-encode a filename for use in a URL path (handles the %2F, <, >, ;,
# ( ) etc. that appear literally in the DOI-encoded source-table filenames)
pct <- function(s) {
  bytes <- charToRaw(enc2utf8(s))
  out <- vapply(bytes, function(b) {
    ch <- rawToChar(b)
    if (grepl("[A-Za-z0-9._~-]", ch)) ch
    else sprintf("%%%02X", as.integer(b))
  }, character(1))
  paste0(out, collapse = "")
}

# Read a file, trying GitHub first, then the local fallback copy.
# `reader` is given a URL string (GitHub) or a path (local) and manages its
# own connection (read.csv/read.delim open and close the URL themselves).
read_gh <- function(gh_rel, local, reader, required = TRUE) {
  res <- tryCatch(reader(paste0(GH_BASE, gh_rel)), error = function(e) NULL)
  if (!is.null(res)) return(res)
  if (file.exists(local)) {
    message("GitHub fetch failed for ", gh_rel, " — using local fallback.")
    return(tryCatch(reader(local), error = function(e) NULL))
  }
  if (required) stop("Could not load ", gh_rel, " from GitHub or local fallback.")
  NULL
}

read_csv_gh   <- function(gh_rel, local) read_gh(gh_rel, local,
  function(x) read.csv(x, stringsAsFactors = FALSE, check.names = FALSE))
read_delim_gh <- function(gh_rel, local, required = TRUE) read_gh(gh_rel, local,
  function(x) read.delim(x, stringsAsFactors = FALSE, check.names = FALSE),
  required = required)

# GitHub locations: compiled tables from their canonical repo paths; the two
# derived tables from the committed build output under __ShinyApp/data.
GH <- list(
  volumes    = "__merging_volumes/volumes_long.csv",
  cellcounts = "__merging_cellcounts/cellcounts_long.csv",
  traits     = "__ShinyApp/data/evom1_traits_long.csv",
  manifest   = "__ShinyApp/data/source_manifest.csv"
)
SRC_DIR <- "__Public/comparative-data/"  # source tables (fetched on demand)

# ---- Load & harmonize compiled data (once, at startup) ----------------------

load_compiled <- function() {
  # Value is kept as text (so categorical traits like Diet are shown as-is);
  # Value_num is the numeric parse used for plotting.
  std <- function(gh_rel, local, dataset, source_col, n_col = NULL) {
    d <- read_csv_gh(gh_rel, local)
    data.frame(
      Species   = d$Species,
      Dataset   = dataset,
      Variable  = d$Variable,
      Value     = as.character(d$Value),
      Value_num = suppressWarnings(as.numeric(d$Value)),
      Source    = d[[source_col]],
      N_sources = if (!is.null(n_col)) suppressWarnings(as.integer(d[[n_col]]))
                  else NA_integer_,
      stringsAsFactors = FALSE
    )
  }

  out <- rbind(
    std(GH$volumes,    file.path(data_dir, "volumes_long.csv"),
        "Brain-structure volumes", "Teams", "n_teams"),
    std(GH$cellcounts, file.path(data_dir, "cellcounts_long.csv"),
        "Cell counts", "Source"),
    std(GH$traits,     file.path(data_dir, "evom1_traits_long.csv"),
        "EvoM1 traits", "Source")
  )
  out <- out[!is.na(out$Value) & nzchar(out$Value), ]
  out[order(out$Species, out$Variable), ]
}

compiled <- load_compiled()

manifest <- read_csv_gh(GH$manifest, file.path(data_dir, "source_manifest.csv"))
manifest <- manifest[order(manifest$identifier, manifest$table_label), ]
# Friendly label for the source-table picker: citation + table label
manifest$picker <- paste0(manifest$citation_short,
                          ifelse(nzchar(manifest$table_label),
                                 paste0("  —  ", manifest$table_label), ""))

sp_choices  <- sort(unique(compiled$Species))
var_choices <- sort(unique(compiled$Variable))

# ---- UI ---------------------------------------------------------------------

ui <- page_navbar(
  title = "Evo-M1 Comparative Brain-Trait Data",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  fillable = FALSE,

  # ---------------------------------------------------------------- Compiled --
  nav_panel(
    title = "Compiled database",
    layout_sidebar(
      sidebar = sidebar(
        width = 340,
        helpText("Harmonized cross-species measurements. Filter, then download ",
                 "or plot the current selection."),
        selectInput("c_dataset", "Dataset",
                    choices = sort(unique(compiled$Dataset)),
                    selected = sort(unique(compiled$Dataset)),
                    multiple = TRUE),
        selectizeInput("c_species", "Species (blank = all)",
                       choices = NULL, multiple = TRUE,
                       options = list(placeholder = "Type to search species...",
                                      maxOptions = 2000)),
        selectizeInput("c_variable", "Measurement / structure (blank = all)",
                       choices = NULL, multiple = TRUE,
                       options = list(placeholder = "Type to search variables...",
                                      maxOptions = 2000)),
        textInput("c_source", "Source contains", placeholder = "e.g. Stephan"),
        downloadButton("c_download", "Download current table (CSV)",
                       class = "btn-primary btn-sm")
      ),
      navset_card_tab(
        nav_panel(
          "Table",
          uiOutput("c_count"),
          DTOutput("c_table")
        ),
        nav_panel(
          "Plot (X vs Y)",
          layout_columns(
            col_widths = c(4, 4, 4),
            selectizeInput("p_x", "X variable", choices = NULL),
            selectizeInput("p_y", "Y variable", choices = NULL),
            checkboxInput("p_log", "Log₁₀ both axes", value = TRUE)
          ),
          helpText("Each point is a species with values for both variables ",
                   "(mean if several sources)."),
          plotOutput("p_plot", height = "540px")
        )
      )
    )
  ),

  # ------------------------------------------------------------ Source tables --
  nav_panel(
    title = "Source tables",
    navset_card_tab(
      # ---- browse the catalogue
      nav_panel(
        "Catalogue",
        p(class = "text-muted",
          "One row per published table extracted for this project. ",
          "Click a row's link to open its source; use the ",
          strong("Open a table"), " tab to view the data."),
        DTOutput("m_table")
      ),
      # ---- open one table
      nav_panel(
        "Open a table",
        layout_sidebar(
          sidebar = sidebar(
            width = 360,
            selectInput("s_type", "Source type",
                        choices = c("All", sort(unique(manifest$id_type))),
                        selected = "All"),
            selectizeInput("s_pick", "Table",
                           choices = NULL,
                           options = list(placeholder = "Type to search tables...")),
            uiOutput("s_meta"),
            downloadButton("s_download", "Download this table (TSV)",
                           class = "btn-primary btn-sm")
          ),
          uiOutput("s_readme"),
          DTOutput("s_table")
        )
      )
    )
  ),

  # -------------------------------------------------------------------- About --
  nav_panel(
    title = "About",
    div(
      class = "container", style = "max-width: 820px;",
      h3("Evo-M1 Comparative Brain-Trait Data"),
      p("An interface to search and download comparative brain-trait data ",
        "compiled for the Evo-M1 project."),
      h5("Compiled database"),
      p("Measurements from many primary sources, harmonized to common species ",
        "names and structure terms. ", strong(format(nrow(compiled), big.mark = ",")),
        " values across ", strong(length(sp_choices)), " species and ",
        strong(length(var_choices)), " measurements, spanning three datasets: ",
        strong("brain-structure volumes"), ", ", strong("cell counts"), ", and the ",
        strong("EvoM1 trait table"), " (dexterity, corticospinal tract, ",
        "gyrification, interlaminar astrocytes, life-history / ecology, plus ",
        "locomotion, manipulation complexity, and hand preference — behavioural ",
        "axes for M1 cell-type correlates)."),
      h5("Source tables"),
      p(strong(nrow(manifest)), " published tables, each shown with its full ",
        "citation and linked to its original DOI, PubMed ID, ISBN, or ",
        "dissertation record."),
      hr(),
      h5("License & attribution"),
      p("This compilation is released under a ",
        tags$a(href = "https://creativecommons.org/licenses/by/4.0/",
               target = "_blank", "Creative Commons Attribution 4.0 (CC BY 4.0)"),
        " license. You are free to share and adapt the data for any purpose, ",
        "provided you give appropriate credit."),
      p(strong("How to cite: "),
        "de Sousa, A. et al. Evo-M1 Comparative Brain-Trait Data (",
        format(Sys.Date(), "%Y"), "). Compiled dataset."),
      p(class = "text-muted small",
        "Important: the compiled tables aggregate work by many original authors. ",
        "When using individual values, please also cite the corresponding ",
        "primary source(s) listed in the Source tables tab and in each value's ",
        "Source column. Every effort has been made to attribute data correctly; ",
        "please report any errors so they can be corrected.")
    )
  ),

  nav_spacer(),
  nav_item(tags$span(class = "text-muted small",
                     paste0(format(nrow(compiled), big.mark = ","), " compiled values")))
)

# ---- Server -----------------------------------------------------------------

server <- function(input, output, session) {

  # server-side choices (fast for large lists)
  updateSelectizeInput(session, "c_species", choices = sp_choices, server = TRUE)
  updateSelectizeInput(session, "c_variable", choices = var_choices, server = TRUE)
  updateSelectizeInput(session, "p_x", choices = var_choices, server = TRUE,
                       selected = "Body_Mass.g")
  updateSelectizeInput(session, "p_y", choices = var_choices, server = TRUE,
                       selected = "Neocortex_Vol.mm3")

  # ---- Compiled: filtered data
  c_filtered <- reactive({
    d <- compiled
    if (length(input$c_dataset)) d <- d[d$Dataset %in% input$c_dataset, ]
    if (length(input$c_species))  d <- d[d$Species  %in% input$c_species, ]
    if (length(input$c_variable)) d <- d[d$Variable %in% input$c_variable, ]
    if (nzchar(input$c_source))
      d <- d[grepl(input$c_source, d$Source, ignore.case = TRUE), ]
    d
  })

  output$c_count <- renderUI({
    n <- nrow(c_filtered())
    div(class = "mb-2 text-muted",
        paste0(format(n, big.mark = ","), " row",
               if (n == 1) "" else "s", " selected"))
  })

  # columns shown / downloaded (hide the internal numeric-parse column)
  c_display <- reactive({
    d <- c_filtered()
    d[, c("Species", "Dataset", "Variable", "Value", "Source", "N_sources")]
  })

  output$c_table <- renderDT({
    datatable(c_display(),
              rownames = FALSE, filter = "top",
              options = list(pageLength = 25, scrollX = TRUE,
                             order = list(list(0, "asc"))))
  })

  output$c_download <- downloadHandler(
    filename = function() paste0("evom1_compiled_", Sys.Date(), ".csv"),
    content  = function(file) write.csv(c_display(), file, row.names = FALSE)
  )

  # ---- Compiled: plot
  p_data <- reactive({
    req(input$p_x, input$p_y)
    d  <- compiled[compiled$Variable %in% c(input$p_x, input$p_y) &
                     !is.na(compiled$Value_num), ]
    if (nrow(d) == 0) return(NULL)
    ag <- aggregate(Value_num ~ Species + Variable, data = d, FUN = mean)
    names(ag)[names(ag) == "Value_num"] <- "Value"
    w  <- reshape(ag, idvar = "Species", timevar = "Variable", direction = "wide")
    names(w) <- sub("^Value\\.", "", names(w))
    keep <- c("Species", input$p_x, input$p_y)
    keep <- keep[keep %in% names(w)]
    if (length(keep) < 3) return(NULL)
    w <- w[, keep]
    w <- w[stats::complete.cases(w), ]
    w
  })

  output$p_plot <- renderPlot({
    w <- p_data()
    validate(need(!is.null(w) && nrow(w) > 0,
                  "No species have values for both selected variables."))
    x <- input$p_x; y <- input$p_y
    g <- ggplot(w, aes(x = .data[[x]], y = .data[[y]])) +
      geom_point(alpha = 0.75, size = 2.4, colour = "#2c7fb8") +
      labs(x = x, y = y,
           subtitle = paste(nrow(w), "species with both measurements")) +
      theme_minimal(base_size = 14)
    if (isTRUE(input$p_log)) {
      g <- g + scale_x_log10() + scale_y_log10() +
        geom_smooth(method = "lm", se = FALSE, linewidth = 0.6,
                    colour = "#d95f0e")
    }
    g
  })

  # ---- Source tables: catalogue
  output$m_table <- renderDT({
    m <- manifest
    # Link uses the DOI/PMID/ISBN as its visible text; falls back to identifier.
    link <- ifelse(nzchar(m$url),
                   paste0("<a href='", m$url, "' target='_blank'>",
                          m$identifier, "</a>"),
                   m$identifier)
    tab <- data.frame(
      Citation = m$citation,
      Table    = m$table_label,
      Rows     = m$n_rows,
      Cols     = m$n_cols,
      Link     = link,
      stringsAsFactors = FALSE
    )
    datatable(tab, rownames = FALSE, filter = "top", escape = FALSE,
              options = list(pageLength = 25,
                             columnDefs = list(list(width = "48%", targets = 0))))
  })

  # ---- Source tables: picker filtered by type
  s_manifest <- reactive({
    m <- manifest
    if (!is.null(input$s_type) && input$s_type != "All")
      m <- m[m$id_type == input$s_type, ]
    m
  })

  observeEvent(s_manifest(), {
    m <- s_manifest()
    choices <- stats::setNames(m$file, m$picker)
    updateSelectizeInput(session, "s_pick", choices = choices, server = TRUE)
  })

  s_row <- reactive({
    req(input$s_pick)
    manifest[manifest$file == input$s_pick, , drop = FALSE][1, ]
  })

  # Source tables are fetched from GitHub on demand (with a local fallback if a
  # bundled copy happens to exist, e.g. during local development).
  s_data <- reactive({
    req(input$s_pick)
    d <- read_delim_gh(paste0(SRC_DIR, pct(input$s_pick)),
                       file.path(data_dir, "source-tables", input$s_pick),
                       required = FALSE)
    validate(need(!is.null(d),
                  "Could not load this table from GitHub. Check your connection and try again."))
    d
  })

  output$s_meta <- renderUI({
    r <- s_row()
    tagList(
      hr(),
      tags$dl(
        tags$dt("Citation"),   tags$dd(if (nzchar(r$citation)) r$citation else r$identifier),
        if (nzchar(r$table_label)) tagList(tags$dt("Table"), tags$dd(r$table_label)),
        tags$dt("Size"), tags$dd(paste0(r$n_rows, " rows × ", r$n_cols, " cols"))
      ),
      if (nzchar(r$url))
        tags$a(href = r$url, target = "_blank", class = "btn btn-outline-secondary btn-sm",
               paste0("Open ", r$identifier, " ↗"))
    )
  })

  output$s_readme <- renderUI({
    r <- s_row()
    if (is.null(r) || !nzchar(r$readme)) return(NULL)
    txt <- tryCatch(
      paste(readLines(url(paste0(GH_BASE, SRC_DIR, pct(r$readme))), warn = FALSE),
            collapse = "\n"),
      error = function(e) {
        p <- file.path(data_dir, "source-tables", r$readme)
        if (file.exists(p)) paste(readLines(p, warn = FALSE), collapse = "\n") else NULL
      })
    if (is.null(txt) || !nzchar(txt)) return(NULL)
    div(class = "alert alert-light border small", style = "white-space: pre-wrap;",
        strong("Source note:"), tags$br(), txt)
  })

  output$s_table <- renderDT({
    datatable(s_data(), rownames = FALSE, filter = "top",
              options = list(pageLength = 25, scrollX = TRUE))
  })

  output$s_download <- downloadHandler(
    filename = function() req(input$s_pick),
    content  = function(file)
      write.table(s_data(), file, sep = "\t", row.names = FALSE, quote = TRUE)
  )
}

shinyApp(ui, server)
