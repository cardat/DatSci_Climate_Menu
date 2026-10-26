###############################################################################
# CLIMATE MENU - ABS ASGS EDITION 3 / 2021 REMOTE GEOGRAPHY
###############################################################################

climate_menu_abs_geography_registry <- function() {

  data.frame(
    geography_type = c(
      "STE", "GCCSA", "SA4", "SA3", "SA2", "SA1", "LGA"
    ),
    label = c(
      "State / Territory",
      "Greater Capital City Statistical Area (GCCSA)",
      "Statistical Area Level 4 (SA4)",
      "Statistical Area Level 3 (SA3)",
      "Statistical Area Level 2 (SA2)",
      "Statistical Area Level 1 (SA1)",
      "Local Government Area (LGA)"
    ),
    service = c(
      "STE", "GCCSA", "SA4", "SA3", "SA2", "SA1", "LGA"
    ),
    layer_id = rep(0L, 7),
    code_field = c(
      "state_code_2021",
      "gccsa_code_2021",
      "sa4_code_2021",
      "sa3_code_2021",
      "sa2_code_2021",
      "sa1_code_2021",
      "lga_code_2021"
    ),
    name_field = c(
      "state_name_2021",
      "gccsa_name_2021",
      "sa4_name_2021",
      "sa3_name_2021",
      "sa2_name_2021",
      NA_character_,
      "lga_name_2021"
    ),
    asgs_year = rep(2021L, 7),
    target_epsg = rep(7844L, 7),
    stringsAsFactors = FALSE
  )
}


climate_menu_abs_registry_row <- function(geography_type) {

  geography_type <- toupper(trimws(as.character(geography_type)))

  reg <- climate_menu_abs_geography_registry()

  ans <- reg[
    reg$geography_type == geography_type,
    ,
    drop = FALSE
  ]

  if (nrow(ans) != 1L) {
    stop("Unsupported ABS geography type: ", geography_type)
  }

  ans
}


climate_menu_abs_layer_url <- function(geography_type) {

  x <- climate_menu_abs_registry_row(geography_type)

  sprintf(
    paste0(
      "https://geo.abs.gov.au/arcgis/rest/services/",
      "ASGS2021/%s/FeatureServer/%s"
    ),
    x$service[[1]],
    x$layer_id[[1]]
  )
}


climate_menu_abs_sql_quote <- function(x) {
  gsub("'", "''", as.character(x), fixed = TRUE)
}


climate_menu_abs_encode <- function(x) {
  utils::URLencode(as.character(x), reserved = TRUE)
}


climate_menu_abs_query_json <- function(
  geography_type,
  where = "1=1",
  out_fields = "*",
  return_geometry = FALSE,
  order_by = NULL,
  result_record_count = NULL
) {

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required.")
  }

  url <- paste0(
    climate_menu_abs_layer_url(geography_type),
    "/query?",
    "where=", climate_menu_abs_encode(where),
    "&outFields=", climate_menu_abs_encode(out_fields),
    "&returnGeometry=",
    ifelse(return_geometry, "true", "false")
  )

  if (!is.null(order_by)) {
    url <- paste0(
      url,
      "&orderByFields=",
      climate_menu_abs_encode(order_by)
    )
  }

  if (!is.null(result_record_count)) {
    url <- paste0(
      url,
      "&resultRecordCount=",
      as.integer(result_record_count)
    )
  }

  url <- paste0(url, "&f=json")

  x <- jsonlite::fromJSON(url)

  if (!is.null(x$error)) {
    stop(
      "ABS service returned an error for ",
      geography_type
    )
  }

  x
}


list_abs_geography_choices <- function(
  geography_type,
  parent_field = NULL,
  parent_value = NULL
) {

  x <- climate_menu_abs_registry_row(geography_type)

  code_field <- x$code_field[[1]]
  name_field <- x$name_field[[1]]

  where <- "1=1"

  if (!is.null(parent_field) &&
      !is.null(parent_value) &&
      nzchar(parent_field) &&
      nzchar(parent_value)) {

    where <- sprintf(
      "%s='%s'",
      parent_field,
      climate_menu_abs_sql_quote(parent_value)
    )
  }

  fields <- "*"

  response <- climate_menu_abs_query_json(
    geography_type = geography_type,
    where = where,
    out_fields = fields,
    return_geometry = FALSE,
    order_by = code_field
  )

  if (is.null(response$features) ||
      !nrow(response$features)) {

    return(
      data.frame(
        code = character(),
        name = character(),
        display = character(),
        stringsAsFactors = FALSE
      )
    )
  }

  attrs <- response$features$attributes

  if (!is.data.frame(attrs)) {
    attrs <- as.data.frame(attrs, stringsAsFactors = FALSE)
  }

  code <- as.character(attrs[[code_field]])

  if (!is.na(name_field) &&
      name_field %in% names(attrs)) {
    name <- as.character(attrs[[name_field]])
  } else {
    name <- code
  }

  display <- ifelse(
    !is.na(name) & nzchar(name) & name != code,
    paste0(name, " [", code, "]"),
    code
  )

  ans <- data.frame(
    code = code,
    name = name,
    display = display,
    stringsAsFactors = FALSE
  )

  ans <- ans[
    !is.na(ans$code) & nzchar(ans$code),
    ,
    drop = FALSE
  ]

  ans <- ans[
    !duplicated(ans$code),
    ,
    drop = FALSE
  ]

  ans <- ans[
    order(tolower(ans$name), ans$code),
    ,
    drop = FALSE
  ]

  rownames(ans) <- NULL
  ans
}


fetch_abs_geography <- function(
  geography_type,
  codes = NULL,
  names = NULL,
  target_epsg = 7844L
) {

  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required.")
  }

  x <- climate_menu_abs_registry_row(geography_type)

  code_field <- x$code_field[[1]]
  name_field <- x$name_field[[1]]

  codes <- if (is.null(codes)) {
    character()
  } else {
    unique(trimws(as.character(codes)))
  }

  names <- if (is.null(names)) {
    character()
  } else {
    unique(trimws(as.character(names)))
  }

  codes <- codes[nzchar(codes)]
  names <- names[nzchar(names)]

  if (length(codes)) {

    values <- paste0(
      "'",
      vapply(
        codes,
        climate_menu_abs_sql_quote,
        character(1)
      ),
      "'"
    )

    where <- sprintf(
      "%s IN (%s)",
      code_field,
      paste(values, collapse = ",")
    )

  } else if (length(names)) {

    if (is.na(name_field)) {
      stop(
        geography_type,
        " has no geography-specific name field; select by code."
      )
    }

    values <- paste0(
      "'",
      vapply(
        names,
        climate_menu_abs_sql_quote,
        character(1)
      ),
      "'"
    )

    where <- sprintf(
      "%s IN (%s)",
      name_field,
      paste(values, collapse = ",")
    )

  } else {

    stop("Provide at least one geography code or name.")
  }

  url <- paste0(
    climate_menu_abs_layer_url(geography_type),
    "/query?",
    "where=", climate_menu_abs_encode(where),
    "&outFields=*",
    "&returnGeometry=true",
    "&outSR=", as.integer(target_epsg),
    "&f=geojson"
  )

  ans <- tryCatch(
    sf::st_read(url, quiet = TRUE),
    error = function(e) e
  )

  if (inherits(ans, "error")) {
    stop(
      "ABS geometry retrieval failed for ",
      geography_type,
      ": ",
      conditionMessage(ans)
    )
  }

  if (!inherits(ans, "sf") || nrow(ans) < 1L) {
    stop("ABS returned no selected geography.")
  }

  if (is.na(sf::st_crs(ans))) {
    stop("ABS geography returned without a recognised CRS.")
  }

  if (is.na(sf::st_crs(ans)$epsg) ||
      sf::st_crs(ans)$epsg != as.integer(target_epsg)) {

    ans <- sf::st_transform(ans, as.integer(target_epsg))
  }

  if (!all(sf::st_is_valid(ans))) {
    ans <- sf::st_make_valid(ans)
  }

  ans$GEO_TYPE <- toupper(geography_type)
  ans$GEO_ID <- as.character(ans[[code_field]])

  if (!is.na(name_field) &&
      name_field %in% names(ans)) {
    ans$GEO_NAME <- as.character(ans[[name_field]])
  } else {
    ans$GEO_NAME <- ans$GEO_ID
  }

  attr(ans, "climate_menu_boundary_provenance") <- list(
    source = "Australian Bureau of Statistics",
    standard = "ASGS Edition 3",
    reference_year = 2021L,
    datum = "GDA2020",
    epsg = as.integer(target_epsg),
    geography_type = toupper(geography_type),
    service = climate_menu_abs_layer_url(geography_type),
    retrieved_utc = format(
      Sys.time(),
      tz = "UTC",
      usetz = TRUE
    )
  )

  ans
}


build_abs_climate_menu_roi <- function(
  geography_type,
  geography_codes = NULL,
  geography_names = NULL,
  combine_geographies = TRUE,
  roi_id = "ROI_001",
  padding_cells = 1L
) {

  selected <- fetch_abs_geography(
    geography_type = geography_type,
    codes = geography_codes,
    names = geography_names,
    target_epsg = 7844L
  )

  selected_wgs84 <- sf::st_transform(selected, 4326)

  if (isTRUE(combine_geographies)) {

    union_geometry <- sf::st_union(
      sf::st_geometry(selected_wgs84)
    )

    geometry <- sf::st_sf(
      roi_id = roi_id,
      geometry = union_geometry
    )

  } else {

    geometry <- selected_wgs84
  }

  list(
    roi_id = roi_id,
    mode = "named_geography",
    geography_type = toupper(geography_type),
    geography_ids = selected$GEO_ID,
    geography_names = selected$GEO_NAME,
    combine_geographies = isTRUE(combine_geographies),
    geometry = geometry,
    selected_features = selected_wgs84,
    bbox_wgs84 = sf::st_bbox(selected_wgs84),
    padding_cells = as.integer(padding_cells),
    boundary_source = "Australian Bureau of Statistics",
    boundary_standard = "ASGS Edition 3 / 2021",
    boundary_datum = "GDA2020",
    provenance = attr(
      selected,
      "climate_menu_boundary_provenance"
    )
  )
}
