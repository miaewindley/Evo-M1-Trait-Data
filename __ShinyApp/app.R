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

# ---- Load & harmonize data (once, at startup) -------------------------------

data_dir <- "data"

load_compiled <- function() {
  vol <- read.csv(file.path(data_dir, "volumes_long.csv"),
                  stringsAsFactors = FALSE, check.names = FALSE)
  # columns: Species, Variable, Value, Teams, n_teams
  vol_std <- data.frame(
    Species   = vol$Species,
    Dataset   = "Brain-structure volumes",
    Variable  = vol$Variable,
    Value     = suppressWarnings(as.numeric(vol$Value)),
    Source    = vol$Teams,
    N_sources = suppressWarnings(as.integer(vol$n_teams)),
    stringsAsFactors = FALSE
  )

  cc <- read.csv(file.path(data_dir, "cellcounts_long.csv"),
                 stringsAsFactors = FALSE, check.names = FALSE)
  # columns: Species, Variable, Value, Source
  cc_std <- data.frame(
    Species   = cc$Species,
    Dataset   = "Cell counts",
    Variable  = cc$Variable,
    Value     = suppressWarnings(as.numeric(cc$Value)),
    Source    = cc$Source,
    N_sources = NA_integer_,
    stringsAsFactors = FALSE
  )

  out <- rbind(vol_std, cc_std)
  out <- out[!is.na(out$Value), ]
  out[order(out$Species, out$Variable), ]
}

compiled <- load_compiled()

manifest <- read.csv(file.path(data_dir, "source_manifest.csv"),
                     stringsAsFactors = FALSE, check.names = FALSE)
manifest <- manifest[order(manifest$identifier, manifest$table_label), ]
# Friendly label for the source-table picker
manifest$picker <- paste0(manifest$identifier,
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
        strong(length(var_choices)), " measurements, spanning brain-structure ",
        "volumes and cell counts."),
      h5("Source tables"),
      p(strong(nrow(manifest)), " published tables, each traceable to its ",
        "original DOI, PubMed ID, ISBN, or dissertation record."),
      hr(),
      p(class = "text-muted",
        "Please cite the original sources when using individual values. ",
        "The compiled tables aggregate work by many authors.")
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

  output$c_table <- renderDT({
    datatable(c_filtered(),
              rownames = FALSE, filter = "top",
              options = list(pageLength = 25, scrollX = TRUE,
                             order = list(list(0, "asc"))))
  })

  output$c_download <- downloadHandler(
    filename = function() paste0("evom1_compiled_", Sys.Date(), ".csv"),
    content  = function(file) write.csv(c_filtered(), file, row.names = FALSE)
  )

  # ---- Compiled: plot
  p_data <- reactive({
    req(input$p_x, input$p_y)
    d  <- compiled[compiled$Variable %in% c(input$p_x, input$p_y), ]
    ag <- aggregate(Value ~ Species + Variable, data = d, FUN = mean)
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
    m <- manifest[, c("identifier", "id_type", "table_label",
                      "n_rows", "n_cols", "url")]
    m$url <- ifelse(nzchar(m$url),
                    paste0("<a href='", m$url, "' target='_blank'>link</a>"),
                    "")
    names(m) <- c("Identifier", "Type", "Table", "Rows", "Cols", "Source")
    datatable(m, rownames = FALSE, filter = "top", escape = FALSE,
              options = list(pageLength = 25))
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

  s_data <- reactive({
    req(input$s_pick)
    read.delim(file.path(data_dir, "source-tables", input$s_pick),
               stringsAsFactors = FALSE, check.names = FALSE)
  })

  output$s_meta <- renderUI({
    r <- s_row()
    tagList(
      hr(),
      tags$dl(
        tags$dt("Identifier"), tags$dd(r$identifier),
        tags$dt("Type"),       tags$dd(r$id_type),
        if (nzchar(r$table_label)) tagList(tags$dt("Table"), tags$dd(r$table_label)),
        tags$dt("Size"), tags$dd(paste0(r$n_rows, " rows × ", r$n_cols, " cols"))
      ),
      if (nzchar(r$url))
        tags$a(href = r$url, target = "_blank", class = "btn btn-outline-secondary btn-sm",
               "Open source ↗")
    )
  })

  output$s_readme <- renderUI({
    r <- s_row()
    if (is.null(r) || !nzchar(r$readme)) return(NULL)
    p <- file.path(data_dir, "source-tables", r$readme)
    if (!file.exists(p)) return(NULL)
    txt <- paste(readLines(p, warn = FALSE), collapse = "\n")
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
