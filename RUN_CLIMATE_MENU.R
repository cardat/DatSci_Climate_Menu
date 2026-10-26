###############################################################################
# CLIMATE MENU
# Portable launcher
###############################################################################

required_packages <- c(
  "shiny",
  "targets",
  "tarchetypes",
  "terra",
  "sf",
  "ncdf4",
  "dplyr",
  "tidyr",
  "purrr",
  "ggplot2",
  "lubridate",
  "jsonlite",
  "httr",
  "digest"
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages)) {

  message("")
  message("Climate Menu needs the following R packages:")
  message(paste(missing_packages, collapse = ", "))
  message("")
  message("Install them with:")
  message(
    "install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "),
    "))"
  )
  message("")

  stop("Required R packages are missing.")
}

project_dir <- normalizePath(
  getwd(),
  winslash = "/",
  mustWork = TRUE
)

message("Climate Menu")
message("Project directory: ", project_dir)
message("Starting application...")

shiny::runApp(
  "app_20261026_v06.R",
  launch.browser = TRUE
)
