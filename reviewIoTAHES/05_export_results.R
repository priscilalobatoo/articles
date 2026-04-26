# =========================================================
# 05_export_results.R
# Export final corpus and core metadata tables
# =========================================================
#
# Inputs
# ------
# processed_data/base_unificada.rds
#
# Outputs
# -------
# outputs/tables/final_dataset.csv/.xlsx
# outputs/tables/final_dataset_minimal.csv/.xlsx
# =========================================================

library(dplyr)
library(openxlsx)

cat("Starting export of final results...\n")

# ---------------------------------------------------------
# 1. Load final database
# ---------------------------------------------------------
if (!exists("base_unificada")) {
  if (!file.exists("processed_data/base_unificada.rds")) {
    stop("processed_data/base_unificada.rds not found. Run 03_deduplication_merge.R first.")
  }
  base_unificada <- readRDS("processed_data/base_unificada.rds")
}

# ---------------------------------------------------------
# 2. Export complete and minimal datasets
# ---------------------------------------------------------
final_dataset <- base_unificada
minimal_dataset <- base_unificada %>%
  select(any_of(c("AU", "AF", "TI", "PY", "SO", "DI", "AB", "DE", "ID", "C1", "TC", "DB")))

write.csv(final_dataset, "outputs/tables/final_dataset.csv", row.names = FALSE, fileEncoding = "UTF-8")
openxlsx::write.xlsx(final_dataset, "outputs/tables/final_dataset.xlsx", overwrite = TRUE)

write.csv(minimal_dataset, "outputs/tables/final_dataset_minimal.csv", row.names = FALSE, fileEncoding = "UTF-8")
openxlsx::write.xlsx(minimal_dataset, "outputs/tables/final_dataset_minimal.xlsx", overwrite = TRUE)

cat("Export completed successfully.\n")
