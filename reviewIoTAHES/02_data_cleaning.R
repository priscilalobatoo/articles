# =========================================================
# 02_data_cleaning.R
# Cleaning, metadata normalization, and temporal filtering
# =========================================================
#
# Inputs
# ------
# processed_data/base_bruta.rds
#
# Outputs
# -------
# processed_data/base_limpa.rds
# processed_data/base_limpa.csv
# outputs/tables/prisma_counts_cleaning.csv
# =========================================================

library(dplyr)
library(stringr)
library(stringi)

cat("Starting cleaning, standardization, and time filtering...\n")

# ---------------------------------------------------------
# 1. Load raw unified database
# ---------------------------------------------------------
if (!exists("base_bruta")) {
  if (!file.exists("processed_data/base_bruta.rds")) {
    stop("processed_data/base_bruta.rds not found. Run 01_data_import.R first.")
  }
  base_bruta <- readRDS("processed_data/base_bruta.rds")
}

records_imported <- nrow(base_bruta)

# ---------------------------------------------------------
# 2. Helper functions for text normalization
# ---------------------------------------------------------
clean_text <- function(x) {
  x <- as.character(x)
  x <- str_replace_all(x, "[\r\n\t]+", " ")
  x <- str_replace_all(x, "\\s+", " ")
  x <- str_squish(x)
  x[x == ""] <- NA_character_
  x
}

normalize_title_key <- function(x) {
  x <- clean_text(x)
  x <- stringi::stri_trans_general(x, "Latin-ASCII")
  x <- str_to_lower(x)
  x <- str_replace_all(x, "[^a-z0-9]+", " ")
  str_squish(x)
}

normalize_doi <- function(x) {
  x <- clean_text(x)
  x <- str_to_lower(x)
  x <- str_replace(x, "^https?://(dx\\.)?doi\\.org/", "")
  x <- str_replace(x, "^doi:", "")
  str_squish(x)
}

# ---------------------------------------------------------
# 3. Clean main bibliographic fields
# ---------------------------------------------------------
base_limpa <- base_bruta %>%
  mutate(
    across(everything(), clean_text),
    PY_NUM = suppressWarnings(as.integer(str_extract(PY, "\\d{4}"))),
    DI = normalize_doi(DI),
    TITLE_KEY = normalize_title_key(TI),
    TC_NUM = suppressWarnings(as.numeric(TC)),
    TC_NUM = ifelse(is.na(TC_NUM), 0, TC_NUM)
  ) %>%
  # Keep records with title and year inside the search interval.
  filter(!is.na(TI), !is.na(PY_NUM), PY_NUM >= 2016, PY_NUM <= 2026)

records_after_time_filter <- nrow(base_limpa)

# Keep PY as character for Bibliometrix compatibility.
base_limpa$PY <- as.character(base_limpa$PY_NUM)

# ---------------------------------------------------------
# 4. Export cleaned database and PRISMA cleaning counts
# ---------------------------------------------------------
saveRDS(base_limpa, "processed_data/base_limpa.rds")
write.csv(base_limpa, "processed_data/base_limpa.csv", row.names = FALSE, fileEncoding = "UTF-8")

prisma_counts <- data.frame(
  Stage = c("Imported records", "After cleaning and temporal filtering"),
  Records = c(records_imported, records_after_time_filter)
)

write.csv(prisma_counts, "outputs/tables/prisma_counts_cleaning.csv", row.names = FALSE, fileEncoding = "UTF-8")

assign("base_limpa", base_limpa, envir = .GlobalEnv)

cat("Rows after cleaning and time filter: ", nrow(base_limpa), "\n", sep = "")
cat("Cleaning completed successfully.\n")
