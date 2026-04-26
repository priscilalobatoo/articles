# =========================================================
# 04_bibliometric_analysis.R
# Bibliometric analysis with Bibliometrix
# =========================================================
#
# Inputs
# ------
# processed_data/base_unificada.rds
#
# Outputs
# -------
# processed_data/bibliometric_results.rds
# outputs/reports/bibliometrix_summary.txt
# outputs/tables/*.csv and *.xlsx
# =========================================================

library(bibliometrix)
library(dplyr)
library(openxlsx)

cat("Starting bibliometric analysis...\n")

# ---------------------------------------------------------
# 1. Load final bibliometric corpus
# ---------------------------------------------------------
if (!exists("base_unificada")) {
  if (!file.exists("processed_data/base_unificada.rds")) {
    stop("processed_data/base_unificada.rds not found. Run 03_deduplication_merge.R first.")
  }
  base_unificada <- readRDS("processed_data/base_unificada.rds")
}

M <- base_unificada
cat("Bibliometric corpus loaded with ", nrow(M), " records.\n", sep = "")

# ---------------------------------------------------------
# 2. Run Bibliometrix analysis
# ---------------------------------------------------------
results <- biblioAnalysis(M, sep = ";")
summary_results <- summary(object = results, k = 20, pause = FALSE)

saveRDS(results, "processed_data/bibliometric_results.rds")
saveRDS(summary_results, "processed_data/bibliometric_summary.rds")

# Export terminal-style Bibliometrix summary.
capture.output(summary_results, file = "outputs/reports/bibliometrix_summary.txt")

# ---------------------------------------------------------
# 3. Export common Bibliometrix summary tables when available
# ---------------------------------------------------------
export_table <- function(x, file_stub) {
  if (is.null(x)) return(invisible(NULL))
  x <- as.data.frame(x)
  write.csv(x, file.path("outputs/tables", paste0(file_stub, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
  openxlsx::write.xlsx(x, file.path("outputs/tables", paste0(file_stub, ".xlsx")), overwrite = TRUE)
}

export_table(summary_results$MainInformation, "main_information")
export_table(summary_results$AnnualProduction, "annual_scientific_production_bibliometrix")
export_table(summary_results$MostProdAuthors, "most_productive_authors_bibliometrix")
export_table(summary_results$MostRelSources, "most_relevant_sources_bibliometrix")
export_table(summary_results$MostRelKeywords, "most_relevant_keywords_bibliometrix")
export_table(summary_results$MostCitedPapers, "most_cited_papers_bibliometrix")

assign("M", M, envir = .GlobalEnv)
assign("bibliometric_results", results, envir = .GlobalEnv)
assign("bibliometric_summary", summary_results, envir = .GlobalEnv)

cat("Bibliometric analysis completed successfully.\n")
