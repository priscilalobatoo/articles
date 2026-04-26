# =========================================================
# 01_data_import.R
# Multi-source import and harmonization
# =========================================================
#
# Inputs
# ------
# raw_data/scopus.bib : Scopus BibTeX export
# raw_data/wos.txt    : Web of Science plain-text export
# raw_data/ieee.csv   : IEEE Xplore CSV export
#
# Outputs
# -------
# processed_data/base_bruta.rds
# processed_data/base_bruta.csv
# =========================================================

library(bibliometrix)
library(readr)
library(dplyr)
library(tibble)

cat("Starting data import...\n")

# Small helper: use a fallback value when a column is absent.
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# ---------------------------------------------------------
# 1. Validate required input files
# ---------------------------------------------------------
input_files <- c(
  scopus = "raw_data/scopus.bib",
  wos    = "raw_data/wos.txt",
  ieee   = "raw_data/ieee.csv"
)

for (input_file in input_files) {
  if (!file.exists(input_file)) {
    stop("Input file not found: ", input_file)
  }
}

# ---------------------------------------------------------
# 2. Import Scopus and Web of Science using Bibliometrix
# ---------------------------------------------------------
# Bibliometrix converts database-specific exports into a standardized data frame.
scopus <- convert2df(file = input_files[["scopus"]], dbsource = "scopus", format = "bibtex")
cat("Scopus imported successfully: ", nrow(scopus), " records.\n", sep = "")

wos <- convert2df(file = input_files[["wos"]], dbsource = "wos", format = "plaintext")
cat("Web of Science imported successfully: ", nrow(wos), " records.\n", sep = "")

# ---------------------------------------------------------
# 3. Import and map IEEE Xplore CSV fields
# ---------------------------------------------------------
ieee_raw <- read_csv(input_files[["ieee"]], show_col_types = FALSE)
cat("IEEE Xplore imported successfully: ", nrow(ieee_raw), " records.\n", sep = "")
cat("Detected IEEE columns:\n")
print(names(ieee_raw))

map_ieee_to_bibliometrix <- function(df) {
  tibble(
    AU = as.character(df[["Authors"]] %||% NA_character_),
    AF = as.character(df[["Authors"]] %||% NA_character_),
    TI = as.character(df[["Document Title"]] %||% NA_character_),
    PY = as.character(df[["Publication Year"]] %||% NA_character_),
    SO = as.character(df[["Publication Title"]] %||% NA_character_),
    DI = as.character(df[["DOI"]] %||% NA_character_),
    AB = as.character(df[["Abstract"]] %||% NA_character_),
    DE = as.character(df[["Author Keywords"]] %||% NA_character_),
    ID = as.character(df[["IEEE Terms"]] %||% NA_character_),
    C1 = as.character(df[["Author Affiliations"]] %||% NA_character_),
    TC = as.character(df[["Article Citation Count"]] %||% NA_character_),
    CR = as.character(df[["Reference Count"]] %||% NA_character_),
    DB = "IEEE"
  )
}

ieee <- map_ieee_to_bibliometrix(ieee_raw)
cat("IEEE mapped to Bibliometrix-like fields successfully.\n")

# ---------------------------------------------------------
# 4. Harmonize fields across sources
# ---------------------------------------------------------
# These fields are enough for the bibliometric analysis and for the PRISMA/
# ProKnow-C workflows used in the article.
required_cols <- c("AU", "AF", "TI", "PY", "SO", "DI", "AB", "DE", "ID", "C1", "TC", "CR", "DB")

ensure_cols <- function(df, cols) {
  df <- as_tibble(df)

  for (col in cols) {
    if (!col %in% names(df)) {
      df[[col]] <- NA_character_
    }
    df[[col]] <- as.character(df[[col]])
  }

  df[, cols, drop = FALSE]
}

scopus <- ensure_cols(scopus, required_cols)
wos    <- ensure_cols(wos, required_cols)
ieee   <- ensure_cols(ieee, required_cols)

# Add explicit database labels for Scopus and WoS when absent.
scopus$DB[is.na(scopus$DB) | scopus$DB == ""] <- "SCOPUS"
wos$DB[is.na(wos$DB) | wos$DB == ""] <- "WOS"

base_bruta <- bind_rows(scopus, wos, ieee)

# ---------------------------------------------------------
# 5. Export raw unified database
# ---------------------------------------------------------
if (!dir.exists("processed_data")) {
  dir.create("processed_data", recursive = TRUE, showWarnings = FALSE)
}

saveRDS(base_bruta, "processed_data/base_bruta.rds")
write.csv(base_bruta, "processed_data/base_bruta.csv", row.names = FALSE, fileEncoding = "UTF-8")

assign("base_bruta", base_bruta, envir = .GlobalEnv)

cat("Unified raw database created with ", nrow(base_bruta), " records.\n", sep = "")
cat("Import completed successfully.\n")
