# ==============================================================================
# 00_run_pipeline.R
# Reproducible bibliometric pipeline for the article:
# "A Systematic Review and Bibliometric Analysis of IoT Architectures for
# Hybrid Energy Systems"
#
# Purpose:
#   1) Import bibliographic files exported from Web of Science, IEEE Xplore,
#      and Scopus.
#   2) Clean and normalize metadata.
#   3) Apply the 2016--2026 temporal filter.
#   4) Deduplicate records.
#   5) Export processed datasets, tables, and figures used in the article.
#
# Expected folder structure:
#   publication_ready_pipeline/
#   ├── data/raw/                 # Put raw database exports here
#   ├── processed_data/           # Generated processed datasets
#   ├── figures/                  # Generated figures
#   ├── tables/                   # Generated tables
#   └── proknowc/                 # ProKnow-C and technical synthesis scripts
#
# Notes:
#   - This script is intentionally verbose and heavily commented to support
#     reproducibility by reviewers/readers.
#   - Raw database files are not included in the repository unless licensing
#     allows redistribution. Users should place their own exports in data/raw/.
# ===============================================================================

# ----------------------------- User parameters --------------------------------
YEAR_MIN <- 2016
YEAR_MAX <- 2026

RAW_DIR <- file.path("data", "raw")
PROCESSED_DIR <- "processed_data"
FIGURES_DIR <- "figures"
TABLES_DIR <- "tables"
PROKNOWC_PROCESSED_DIR <- file.path("proknowc", "processed_data")

# ----------------------------- Package handling -------------------------------
required_packages <- c(
  "bibliometrix", "dplyr", "readr", "stringr", "tidyr", "ggplot2",
  "forcats", "countrycode", "maps", "scales"
)

install_if_missing <- function(pkgs) {
  missing <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(missing) > 0) {
    install.packages(missing, dependencies = TRUE)
  }
}

install_if_missing(required_packages)
invisible(lapply(required_packages, library, character.only = TRUE))

# ----------------------------- Directory setup --------------------------------
dir.create(PROCESSED_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(FIGURES_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(TABLES_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(PROKNOWC_PROCESSED_DIR, recursive = TRUE, showWarnings = FALSE)

# ----------------------------- Helper functions -------------------------------
clean_text <- function(x) {
  x <- ifelse(is.na(x), "", x)
  x <- stringr::str_replace_all(x, "\\r|\\n|\\t", " ")
  x <- stringr::str_squish(x)
  x
}

normalize_key <- function(x) {
  x <- clean_text(x)
  x <- stringr::str_to_lower(x)
  x <- stringr::str_replace_all(x, "[^a-z0-9]+", " ")
  stringr::str_squish(x)
}

# Convert multiple database export formats into a Bibliometrix-compatible frame.
# The function tries to infer the source database from file names.
read_bibliographic_file <- function(path) {
  file_name <- basename(path)
  ext <- tolower(tools::file_ext(path))
  lower_name <- tolower(file_name)

  dbsource <- dplyr::case_when(
    stringr::str_detect(lower_name, "scopus") ~ "scopus",
    stringr::str_detect(lower_name, "wos|webofscience|web_of_science") ~ "wos",
    stringr::str_detect(lower_name, "ieee") ~ "isi",
    TRUE ~ "scopus"
  )

  format <- dplyr::case_when(
    ext %in% c("bib", "bibtex") ~ "bibtex",
    ext %in% c("csv") ~ "csv",
    ext %in% c("txt") ~ "plaintext",
    ext %in% c("ris") ~ "ris",
    TRUE ~ "csv"
  )

  message("Reading: ", path, " | dbsource=", dbsource, " | format=", format)

  out <- tryCatch(
    bibliometrix::convert2df(file = path, dbsource = dbsource, format = format),
    error = function(e) {
      warning("Could not parse with bibliometrix::convert2df: ", path, "\n", e$message)
      NULL
    }
  )

  if (!is.null(out)) {
    out$SOURCE_FILE <- file_name
    out$SOURCE_DB_INFERRED <- dbsource
  }
  out
}

# Safely access a bibliometrix column, returning blank values when absent.
get_col <- function(df, col_name) {
  if (col_name %in% names(df)) df[[col_name]] else rep("", nrow(df))
}

# Standardize the minimum metadata required by the subsequent scripts.
standardize_metadata <- function(df) {
  df %>%
    mutate(
      TI = clean_text(get_col(., "TI")),
      AB = clean_text(get_col(., "AB")),
      DE = clean_text(get_col(., "DE")),
      ID = clean_text(get_col(., "ID")),
      AU = clean_text(get_col(., "AU")),
      SO = clean_text(get_col(., "SO")),
      PY = suppressWarnings(as.integer(get_col(., "PY"))),
      DI = stringr::str_to_lower(clean_text(get_col(., "DI"))),
      TC = suppressWarnings(as.numeric(get_col(., "TC"))),
      C1 = clean_text(get_col(., "C1")),
      title_key = normalize_key(TI),
      doi_key = stringr::str_replace_all(DI, "\\s+", "")
    ) %>%
    mutate(
      TC = ifelse(is.na(TC), 0, TC)
    )
}

# Deduplicate first by DOI and then by normalized title.
deduplicate_records <- function(df) {
  with_doi <- df %>%
    filter(!is.na(doi_key), doi_key != "") %>%
    arrange(desc(TC), desc(PY)) %>%
    distinct(doi_key, .keep_all = TRUE)

  without_doi <- df %>%
    filter(is.na(doi_key) | doi_key == "") %>%
    arrange(desc(TC), desc(PY)) %>%
    distinct(title_key, .keep_all = TRUE)

  bind_rows(with_doi, without_doi) %>%
    arrange(desc(PY), TI)
}

# Extract country names from affiliation strings when available.
extract_countries <- function(c1_vector) {
  country_names <- countrycode::codelist$country.name.en
  pattern <- paste0("\\b(", paste(unique(country_names), collapse = "|"), ")\\b")

  out <- stringr::str_extract_all(c1_vector, regex(pattern, ignore_case = TRUE))
  out <- lapply(out, function(x) {
    x <- unique(stringr::str_to_title(x))
    x[!is.na(x) & x != ""]
  })
  out
}

# ----------------------------- Import raw data --------------------------------
raw_files <- list.files(
  RAW_DIR,
  pattern = "\\.(bib|bibtex|csv|txt|ris)$",
  full.names = TRUE,
  ignore.case = TRUE
)

if (length(raw_files) == 0) {
  stop(
    "No raw bibliographic files found in data/raw/.\n",
    "Place Web of Science, IEEE Xplore, and Scopus exports in data/raw/ and run again."
  )
}

raw_list <- lapply(raw_files, read_bibliographic_file)
raw_list <- raw_list[!vapply(raw_list, is.null, logical(1))]

if (length(raw_list) == 0) {
  stop("No bibliographic file could be imported. Check data/raw/ file formats.")
}

raw_db <- dplyr::bind_rows(raw_list)
raw_db <- standardize_metadata(raw_db)

# ----------------------------- Cleaning and filtering --------------------------
# Temporal filter applied before deduplication, matching the article method.
clean_temporal <- raw_db %>%
  filter(!is.na(PY), PY >= YEAR_MIN, PY <= YEAR_MAX)

# Deduplicate after cleaning and temporal filtering.
bibliometric_corpus <- deduplicate_records(clean_temporal)

# ----------------------------- Export datasets --------------------------------
readr::write_csv(raw_db, file.path(PROCESSED_DIR, "integrated_raw_database.csv"))
readr::write_csv(clean_temporal, file.path(PROCESSED_DIR, "base_limpa_temporal_filter.csv"))
readr::write_csv(bibliometric_corpus, file.path(PROCESSED_DIR, "base_limpa.csv"))
readr::write_csv(bibliometric_corpus, file.path(PROCESSED_DIR, "bibliometric_corpus_2016_2026_deduplicated.csv"))

# Copy the clean bibliometric corpus to the ProKnow-C folder, because the ProKnow-C
# scripts are intentionally isolated from the main bibliometric pipeline.
readr::write_csv(bibliometric_corpus, file.path(PROKNOWC_PROCESSED_DIR, "base_limpa.csv"))

# ----------------------------- Tables -----------------------------------------
annual_table <- bibliometric_corpus %>%
  count(PY, name = "Publications") %>%
  arrange(PY)
readr::write_csv(annual_table, file.path(TABLES_DIR, "annual_scientific_production.csv"))

author_table <- bibliometric_corpus %>%
  mutate(AU = stringr::str_split(AU, ";")) %>%
  tidyr::unnest(AU) %>%
  mutate(AU = stringr::str_squish(AU)) %>%
  filter(AU != "") %>%
  count(AU, name = "Publications", sort = TRUE)
readr::write_csv(author_table, file.path(TABLES_DIR, "most_productive_authors.csv"))

source_table <- bibliometric_corpus %>%
  mutate(SO = stringr::str_to_title(SO)) %>%
  filter(SO != "") %>%
  count(SO, name = "Publications", sort = TRUE)
readr::write_csv(source_table, file.path(TABLES_DIR, "publication_sources.csv"))

keyword_table <- bibliometric_corpus %>%
  mutate(KEYWORDS = paste(DE, ID, sep = ";")) %>%
  mutate(KEYWORDS = stringr::str_split(KEYWORDS, ";")) %>%
  tidyr::unnest(KEYWORDS) %>%
  mutate(KEYWORDS = stringr::str_to_lower(stringr::str_squish(KEYWORDS))) %>%
  filter(KEYWORDS != "") %>%
  count(KEYWORDS, name = "Frequency", sort = TRUE)
readr::write_csv(keyword_table, file.path(TABLES_DIR, "keyword_frequency.csv"))

countries_long <- bibliometric_corpus %>%
  mutate(COUNTRY = extract_countries(C1)) %>%
  tidyr::unnest(COUNTRY) %>%
  filter(!is.na(COUNTRY), COUNTRY != "") %>%
  mutate(COUNTRY = stringr::str_to_title(COUNTRY))

country_table <- countries_long %>%
  count(COUNTRY, name = "Publications", sort = TRUE)
readr::write_csv(country_table, file.path(TABLES_DIR, "publications_by_country.csv"))

# ----------------------------- Figures ----------------------------------------
# Annual scientific production
p_annual <- ggplot(annual_table, aes(x = PY, y = Publications)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_text(aes(label = Publications), vjust = -0.7, size = 3) +
  labs(
    title = "Annual Scientific Production",
    x = "Year",
    y = "Number of Publications"
  ) +
  theme_minimal(base_size = 11)

ggsave(file.path(FIGURES_DIR, "annual_scientific_production.png"), p_annual, width = 7, height = 4.5, dpi = 600)
ggsave(file.path(FIGURES_DIR, "annual_scientific_production.pdf"), p_annual, width = 7, height = 4.5)

# Most productive authors
top_authors <- author_table %>% slice_head(n = 15)
p_authors <- ggplot(top_authors, aes(x = Publications, y = forcats::fct_reorder(AU, Publications))) +
  geom_col() +
  geom_text(aes(label = Publications), hjust = -0.1, size = 3) +
  labs(
    title = "Most Productive Authors",
    x = "Number of Publications",
    y = "Author"
  ) +
  theme_minimal(base_size = 10) +
  coord_cartesian(xlim = c(0, max(top_authors$Publications) * 1.12))

ggsave(file.path(FIGURES_DIR, "top_authors.png"), p_authors, width = 7, height = 5, dpi = 600)
ggsave(file.path(FIGURES_DIR, "top_authors.pdf"), p_authors, width = 7, height = 5)

# Publication sources
top_sources <- source_table %>% slice_head(n = 15)
p_sources <- ggplot(top_sources, aes(x = Publications, y = forcats::fct_reorder(SO, Publications))) +
  geom_col() +
  geom_text(aes(label = Publications), hjust = -0.1, size = 3) +
  labs(
    title = "Most Relevant Publication Sources",
    x = "Number of Publications",
    y = "Source"
  ) +
  theme_minimal(base_size = 9) +
  coord_cartesian(xlim = c(0, max(top_sources$Publications) * 1.15))

ggsave(file.path(FIGURES_DIR, "top_sources.png"), p_sources, width = 8, height = 5.5, dpi = 600)
ggsave(file.path(FIGURES_DIR, "top_sources.pdf"), p_sources, width = 8, height = 5.5)

# Keyword frequency
top_keywords <- keyword_table %>% slice_head(n = 20)
p_keywords <- ggplot(top_keywords, aes(x = Frequency, y = forcats::fct_reorder(KEYWORDS, Frequency))) +
  geom_col() +
  geom_text(aes(label = Frequency), hjust = -0.1, size = 3) +
  labs(
    title = "Most Frequent Keywords",
    x = "Frequency",
    y = "Keyword"
  ) +
  theme_minimal(base_size = 10) +
  coord_cartesian(xlim = c(0, max(top_keywords$Frequency) * 1.15))

ggsave(file.path(FIGURES_DIR, "top_keywords.png"), p_keywords, width = 8, height = 5.5, dpi = 600)
ggsave(file.path(FIGURES_DIR, "top_keywords.pdf"), p_keywords, width = 8, height = 5.5)

# Country map
world_map <- map_data("world")
country_map_data <- country_table %>%
  mutate(region = countrycode::countrycode(COUNTRY, "country.name", "country.name"))

p_country <- world_map %>%
  left_join(country_map_data, by = "region") %>%
  ggplot(aes(long, lat, group = group, fill = Publications)) +
  geom_polygon(color = "white", linewidth = 0.1) +
  scale_fill_continuous(labels = scales::comma, na.value = "grey90") +
  coord_quickmap() +
  labs(
    title = "Global Distribution of Publications by Country",
    fill = "Publications"
  ) +
  theme_void(base_size = 11) +
  theme(legend.position = "right")

ggsave(file.path(FIGURES_DIR, "publications_by_country_map.png"), p_country, width = 9, height = 4.8, dpi = 600)
ggsave(file.path(FIGURES_DIR, "publications_by_country_map.pdf"), p_country, width = 9, height = 4.8)

# ----------------------------- Run summary ------------------------------------
summary_table <- tibble::tibble(
  metric = c(
    "Integrated raw records",
    "Records after temporal filtering",
    "Deduplicated bibliometric corpus",
    "Year range"
  ),
  value = c(
    nrow(raw_db),
    nrow(clean_temporal),
    nrow(bibliometric_corpus),
    paste0(YEAR_MIN, "--", YEAR_MAX)
  )
)
readr::write_csv(summary_table, file.path(TABLES_DIR, "pipeline_run_summary.csv"))

message("Pipeline completed successfully.")
message("Processed data saved to: ", normalizePath(PROCESSED_DIR))
message("Figures saved to: ", normalizePath(FIGURES_DIR))
message("Tables saved to: ", normalizePath(TABLES_DIR))
message("ProKnow-C input copied to: ", normalizePath(PROKNOWC_PROCESSED_DIR))
