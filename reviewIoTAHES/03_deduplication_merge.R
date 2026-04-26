# =========================================================
# 03_deduplication_merge.R
# Deduplication and final bibliometric corpus creation
# =========================================================
#
# Inputs
# ------
# processed_data/base_limpa.rds
#
# Outputs
# -------
# processed_data/base_unificada.rds
# processed_data/base_unificada.csv
# outputs/tables/prisma_counts_deduplication.csv
# =========================================================

library(dplyr)
library(stringr)

cat("Starting merge and deduplication...\n")

# ---------------------------------------------------------
# 1. Load cleaned database
# ---------------------------------------------------------
if (!exists("base_limpa")) {
  if (!file.exists("processed_data/base_limpa.rds")) {
    stop("processed_data/base_limpa.rds not found. Run 02_data_cleaning.R first.")
  }
  base_limpa <- readRDS("processed_data/base_limpa.rds")
}

records_before_dedup <- nrow(base_limpa)

# ---------------------------------------------------------
# 2. Deduplicate by DOI first, then by normalized title
# ---------------------------------------------------------
# DOI is the strongest identifier. For records without DOI, a normalized title key
# is used. The first occurrence is kept, preserving source order from import.
base_unificada <- base_limpa %>%
  mutate(
    DEDUP_KEY = case_when(
      !is.na(DI) & DI != "" ~ paste0("doi:", DI),
      !is.na(TITLE_KEY) & TITLE_KEY != "" ~ paste0("title:", TITLE_KEY),
      TRUE ~ paste0("row:", row_number())
    )
  ) %>%
  distinct(DEDUP_KEY, .keep_all = TRUE) %>%
  select(-DEDUP_KEY)

records_after_dedup <- nrow(base_unificada)
duplicates_removed <- records_before_dedup - records_after_dedup

# ---------------------------------------------------------
# 3. Export final bibliometric corpus
# ---------------------------------------------------------
saveRDS(base_unificada, "processed_data/base_unificada.rds")
write.csv(base_unificada, "processed_data/base_unificada.csv", row.names = FALSE, fileEncoding = "UTF-8")

prisma_counts <- data.frame(
  Stage = c("Before deduplication", "Duplicates removed", "Final bibliometric corpus"),
  Records = c(records_before_dedup, duplicates_removed, records_after_dedup)
)

write.csv(prisma_counts, "outputs/tables/prisma_counts_deduplication.csv", row.names = FALSE, fileEncoding = "UTF-8")

assign("base_unificada", base_unificada, envir = .GlobalEnv)

cat("Final base after deduplication: ", nrow(base_unificada), " records.\n", sep = "")
cat("Merge and deduplication completed successfully.\n")
