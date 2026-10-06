library(shiny)

app_file <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
if (is.null(app_file) || !nzchar(app_file)) {
  app_file <- file.path(getwd(), "app.R")
}
app_dir <- dirname(normalizePath(app_file, winslash = "/", mustWork = TRUE))
project_root <- normalizePath(
  file.path(app_dir, ".."),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(app_dir, "ui.R"), local = TRUE)
source(file.path(app_dir, "server.R"), local = TRUE)

shinyApp(ui = ui, server = server)