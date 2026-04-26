# ==============================================================================
# 02_generate_architecture_taxonomy_table.R
# Technical taxonomy of IoT architectures for hybrid energy systems
#
# Purpose:
#   Generate the taxonomy table used as Table IV in the article. The taxonomy is
#   based on the top 10 prioritized studies and the broader bibliometric evidence.
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

taxonomy <- tibble::tribble(
  ~taxonomy_dimension, ~main_categories, ~typical_role_in_hybrid_energy_systems, ~main_limitations_identified, ~related_studies,
  "Computing layer", "Cloud-centric; edge-based; fog/edge-cloud; distributed intelligence", "Defines where data storage, processing, analytics, and decision-making are performed", "Latency, connectivity dependence, scalability, and orchestration complexity", "a2024meetingtherequirementsof; b2019fogedgecomputingbased; h2019fogcomputingforinternet",
  "Application domain", "Smart grids; photovoltaic systems; hybrid microgrids; smart buildings", "Defines the operational context and the type of energy service supported by the IoT architecture", "Fragmentation across domains and limited unified architectural models", "k2018internetofthingsiot; u2021energymanagementinsmart; d2018exportandimportof",
  "Energy asset", "Photovoltaic generation; distributed energy resources; hybrid microgrids; smart-building loads; renewable generation assets", "Defines the monitored, forecasted, or controlled physical component of the hybrid energy system", "Limited integration between generation, storage, load-side management, and control", "k2018internetofthingsiot; d2018exportandimportof; u2021energymanagementinsmart; r2025hybridtransformerlstmsolar",
  "Communication infrastructure", "IoT platforms; fog/cloud services; edge nodes; Internet-based APIs; heterogeneous communication protocols", "Enables data transmission between field devices, middleware platforms, edge nodes, and cloud services", "Interoperability, protocol heterogeneity, cybersecurity, and reliability constraints", "b2019fogedgecomputingbased; h2019fogcomputingforinternet; p2025cyberresilienceforsmart",
  "Intelligence level", "Monitoring; control; forecasting; optimization; cyber-resilience; distributed intelligence", "Indicates whether the architecture only observes the system or also supports predictive and adaptive operation", "Limited adoption of advanced intelligence in real deployments", "p2025cyberresilienceforsmart; r2025hybridtransformerlstmsolar; a2025designandsimulationof",
  "Validation level", "Review; conceptual model; simulation; prototype; application-oriented implementation", "Indicates the maturity and practical readiness of the proposed architecture", "Few long-term field validations in constrained or isolated environments", "a2025designandsimulationof; f2021edgebasedhybridsystem"
)

readr::write_csv(
  taxonomy,
  file.path(OUTPUT_DIR, "iot_architecture_taxonomy_top10.csv")
)

# Generate LaTeX-ready rows for Overleaf.
latex_rows <- taxonomy %>%
  rowwise() %>%
  mutate(
    latex_citations = paste0(
      "\\cite{",
      paste(strsplit(related_studies, ";\\s*")[[1]], collapse = ","),
      "}"
    ),
    latex_row = paste0(
      taxonomy_dimension, " & ",
      main_categories, " & ",
      typical_role_in_hybrid_energy_systems, " & ",
      main_limitations_identified, " & ",
      latex_citations, " \\\\"
    )
  ) %>%
  ungroup() %>%
  pull(latex_row)

writeLines(
  latex_rows,
  con = file.path(OUTPUT_DIR, "iot_architecture_taxonomy_top10_latex_rows.tex")
)

message("Architecture taxonomy table generated.")
message("Output: ", normalizePath(file.path(OUTPUT_DIR, "iot_architecture_taxonomy_top10.csv")))
