# ==============================================================================
# 00_run_proknowc_analysis.R
# Complete ProKnow-C and technical synthesis workflow
#
# Purpose:
#   Run the adapted ProKnow-C prioritization and generate the top 10 technical
#   comparison and architectural taxonomy outputs used in the article.
# ===============================================================================

message("Starting complete ProKnow-C and technical synthesis workflow...")
message("Working directory:")
print(getwd())

OUTPUT_DIR <- "proknowc_analysis_outputs"
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
message("Analysis outputs will be saved in:")
print(normalizePath(OUTPUT_DIR))

# Run ProKnow-C prioritization. The script is located one level above this folder.
message("\nRunning ../00_proknowc.R ...")
source(file.path("..", "00_proknowc.R"))

# Generate curated technical comparison table for top 10 studies.
message("\nRunning 01_generate_technical_comparison_table.R ...")
source("01_generate_technical_comparison_table.R")

# Generate architectural taxonomy table.
message("\nRunning 02_generate_architecture_taxonomy_table.R ...")
source("02_generate_architecture_taxonomy_table.R")

message("\nWorkflow completed successfully.")
message("Check outputs in: ", normalizePath(OUTPUT_DIR))
