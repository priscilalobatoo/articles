# ==============================================================================
# 00_proknowc.R
# Adapted ProKnow-C prioritization script
#
# Purpose:
#   Rank the screened bibliometric corpus according to thematic adherence,
#   citation support, and publication recency. The generated outputs support
#   full-text retrieval and the top 10 technical synthesis used in the article.
#
# Important article decision:
#   The technical synthesis is based ONLY on the top 10 prioritized studies.
#   The former top 20 and the isolated 2026 study are no longer used.
# ===============================================================================

# ----------------------------- User parameters --------------------------------
N_PRIORITIZED_PORTFOLIO <- 104
N_TOP_STUDIES <- 10
YEAR_MAX <- 2026

INPUT_FILE <- file.path("processed_data", "base_limpa.csv")
OUTPUT_DIR <- "proknowc_outputs"

# When this script is sourced from proknowc/proknowc_analysis/, the expected input
# file is located one directory above. This fallback makes the script robust.
if (!file.exists(INPUT_FILE)) {
  alt_input <- file.path("..", "processed_data", "base_limpa.csv")
  if (file.exists(alt_input)) {
    INPUT_FILE <- alt_input
    OUTPUT_DIR <- file.path("..", "proknowc_outputs")
  }
}

# ----------------------------- Package handling -------------------------------
required_packages <- c("dplyr", "readr", "stringr", "tibble")
install_if_missing <- function(pkgs) {
  missing <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(missing) > 0) install.packages(missing, dependencies = TRUE)
}
install_if_missing(required_packages)
invisible(lapply(required_packages, library, character.only = TRUE))

dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# ----------------------------- Helper functions -------------------------------
clean_text <- function(x) {
  x <- ifelse(is.na(x), "", x)
  x <- stringr::str_replace_all(x, "\\r|\\n|\\t", " ")
  stringr::str_squish(x)
}

get_col <- function(df, col_name) {
  if (col_name %in% names(df)) df[[col_name]] else rep("", nrow(df))
}

count_regex_terms <- function(text, terms) {
  text <- stringr::str_to_lower(clean_text(text))
  vapply(
    terms,
    function(term) as.integer(stringr::str_detect(text, stringr::regex(term, ignore_case = TRUE))),
    integer(1)
  ) |>
    sum(na.rm = TRUE)
}

# ----------------------------- Input validation -------------------------------
if (!file.exists(INPUT_FILE)) {
  stop(
    "Input file not found: ", normalizePath(INPUT_FILE, mustWork = FALSE), "\n",
    "Expected location: processed_data/base_limpa.csv or ../processed_data/base_limpa.csv"
  )
}

message("Reading ProKnow-C input file: ", normalizePath(INPUT_FILE))
base <- readr::read_csv(INPUT_FILE, show_col_types = FALSE)

# ----------------------------- Metadata standardization ------------------------
base <- base %>%
  mutate(
    TI = clean_text(get_col(., "TI")),
    AB = clean_text(get_col(., "AB")),
    DE = clean_text(get_col(., "DE")),
    ID = clean_text(get_col(., "ID")),
    AU = clean_text(get_col(., "AU")),
    SO = clean_text(get_col(., "SO")),
    PY = suppressWarnings(as.integer(get_col(., "PY"))),
    TC = suppressWarnings(as.numeric(get_col(., "TC"))),
    DI = clean_text(get_col(., "DI")),
    TC = ifelse(is.na(TC), 0, TC),
    SEARCH_TEXT = paste(TI, AB, DE, ID, sep = " ")
  )

# ----------------------------- Relevance dictionary ----------------------------
# Terms were chosen to reflect the scope of the article: IoT architectures,
# edge/fog/distributed computing, hybrid energy systems, smart grids, renewable
# energy, storage, cybersecurity, and intelligent energy management.
primary_terms <- c(
  "internet of things", "\\biot\\b", "iot architecture", "iot architectures",
  "edge computing", "fog computing", "edge-cloud", "edge cloud",
  "distributed computing", "distributed intelligence",
  "hybrid energy", "hybrid energy system", "hybrid microgrid", "microgrid",
  "smart grid", "photovoltaic", "solar", "renewable energy",
  "energy storage", "battery", "batteries", "supercapacitor", "storage system"
)

secondary_terms <- c(
  "monitoring", "control", "forecasting", "optimization", "energy management",
  "cybersecurity", "cyber-resilience", "resilience", "fault tolerance",
  "communication protocol", "middleware", "cloud computing", "real-time",
  "interoperability", "digital twin", "smart building", "distributed energy"
)

# ----------------------------- Scoring ----------------------------------------
# The adapted score combines:
#   1) thematic adherence: presence of primary and secondary domain terms;
#   2) citation support: log-normalized citation count;
#   3) recency: more recent articles receive a moderate bonus.
#
# The weights can be adjusted, but the exported results should remain documented.
max_citations <- max(base$TC, na.rm = TRUE)
if (!is.finite(max_citations) || max_citations <= 0) max_citations <- 1

base_ranked <- base %>%
  rowwise() %>%
  mutate(
    primary_hits = count_regex_terms(SEARCH_TEXT, primary_terms),
    secondary_hits = count_regex_terms(SEARCH_TEXT, secondary_terms),
    thematic_score = 5 * primary_hits + 2 * secondary_hits,
    citation_score = 20 * log1p(TC) / log1p(max_citations),
    recency_score = pmax(0, 10 - (YEAR_MAX - PY)),
    proknowc_score = thematic_score + citation_score + recency_score
  ) %>%
  ungroup() %>%
  arrange(desc(proknowc_score), desc(TC), desc(PY), TI) %>%
  mutate(priority_rank = dplyr::row_number())

prioritized_portfolio <- base_ranked %>%
  slice_head(n = N_PRIORITIZED_PORTFOLIO)

top10_prioritized <- base_ranked %>%
  slice_head(n = N_TOP_STUDIES)

# ----------------------------- Export outputs ---------------------------------
readr::write_csv(
  base_ranked,
  file.path(OUTPUT_DIR, "proknowc_ranked_all_records.csv")
)

readr::write_csv(
  prioritized_portfolio,
  file.path(OUTPUT_DIR, "proknowc_prioritized_portfolio_104_records.csv")
)

readr::write_csv(
  top10_prioritized,
  file.path(OUTPUT_DIR, "top10_proknowc_prioritized_articles.csv")
)

# Compact version used to manually verify Table I in the article.
top10_table <- top10_prioritized %>%
  transmute(
    priority_rank,
    title = TI,
    year = PY,
    citations = TC,
    proknowc_score = round(proknowc_score, 1),
    doi = DI
  )

readr::write_csv(
  top10_table,
  file.path(OUTPUT_DIR, "top10_proknowc_table_for_article.csv")
)

message("ProKnow-C prioritization completed.")
message("Prioritized portfolio size: ", nrow(prioritized_portfolio))
message("Top studies used in technical synthesis: ", nrow(top10_prioritized))
message("Outputs saved to: ", normalizePath(OUTPUT_DIR))
