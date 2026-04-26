# ==============================================================================
# 01_generate_technical_comparison_table.R
# Technical comparison of the TOP 10 ProKnow-C-prioritized studies
#
# Purpose:
#   Generate the curated technical comparison table used as Table III in the
#   article. This script intentionally uses only the top 10 studies.
# ===============================================================================

required_packages <- c("dplyr", "readr", "tibble")
install_if_missing <- function(pkgs) {
  missing <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(missing) > 0) install.packages(missing, dependencies = TRUE)
}
install_if_missing(required_packages)
invisible(lapply(required_packages, library, character.only = TRUE))

OUTPUT_DIR <- "proknowc_analysis_outputs"
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Article-level decision: keep only the top 10 prioritized studies.
N_TOP_STUDIES <- 10

technical_comparison <- tibble::tribble(
  ~rank, ~citation_key, ~study_focus, ~architecture_type, ~computing_layer, ~energy_domain, ~validation_level, ~main_limitation,
  1, "a2024meetingtherequirementsof", "Edge computing for IoT requirements", "General IoT architecture", "Edge", "Cross-domain IoT", "Conceptual/review", "Limited energy-specific integration",
  2, "b2019fogedgecomputingbased", "Fog/edge computing-based IoT", "Fog/edge IoT architecture", "Fog/edge/cloud", "Cross-domain IoT", "Review", "Orchestration and deployment challenges",
  3, "k2018internetofthingsiot", "IoT in photovoltaic systems", "Monitoring architecture", "Cloud/IoT platform", "Photovoltaic systems", "Review/application-oriented", "Limited integration with storage and control",
  4, "u2021energymanagementinsmart", "Energy management in smart buildings", "Energy management architecture", "Cloud/IoT", "Smart buildings and homes", "Review/conceptual", "Limited hybrid energy-system scope",
  5, "p2025cyberresilienceforsmart", "Cyber-resilience for smart grids", "Security-oriented architecture", "Distributed IoT", "Smart grids", "Conceptual/application-oriented", "Limited real-world validation",
  6, "h2019fogcomputingforinternet", "Fog computing for IoT-aided smart grids", "Smart-grid architecture", "Fog/cloud", "Smart grids", "Conceptual/simulation", "Limited storage integration",
  7, "f2021edgebasedhybridsystem", "Edge-based hybrid IoT system", "Edge-based system", "Edge", "Safety/healthcare IoT", "Prototype", "Not directly energy-oriented",
  8, "a2025designandsimulationof", "Hybrid smart grid using IoT control", "Smart-grid control architecture", "Edge/IoT", "Hybrid smart grid", "Simulation", "Requires field deployment",
  9, "r2025hybridtransformerlstmsolar", "Hybrid Transformer-LSTM forecasting", "Forecasting-oriented architecture", "Cloud/AI", "Renewable energy and microgrids", "Simulation", "Focused on prediction rather than full architecture",
  10, "d2018exportandimportof", "Hybrid microgrid via IoT", "IoT-enabled microgrid architecture", "IoT/cloud", "Hybrid microgrid", "Application-oriented", "Limited edge/fog integration"
)

stopifnot(nrow(technical_comparison) == N_TOP_STUDIES)

readr::write_csv(
  technical_comparison,
  file.path(OUTPUT_DIR, "top10_technical_comparison_table.csv")
)

# Generate a LaTeX-ready table body for easy copy/paste into Overleaf.
latex_rows <- technical_comparison %>%
  mutate(
    latex_row = paste0(
      study_focus, " \\cite{", citation_key, "} & ",
      architecture_type, " & ",
      computing_layer, " & ",
      energy_domain, " & ",
      validation_level, " & ",
      main_limitation, " \\\\"
    )
  ) %>%
  pull(latex_row)

writeLines(
  latex_rows,
  con = file.path(OUTPUT_DIR, "top10_technical_comparison_table_latex_rows.tex")
)

message("Technical comparison table generated with ", nrow(technical_comparison), " studies.")
message("Output: ", normalizePath(file.path(OUTPUT_DIR, "top10_technical_comparison_table.csv")))
