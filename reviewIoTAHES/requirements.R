# =========================================================
# requirements.R
# Install the R packages required by the reproducible pipeline
# =========================================================

required_packages <- c(
  "bibliometrix", "dplyr", "stringr", "stringi", "readr", "tibble",
  "tidyr", "purrr", "ggplot2", "openxlsx", "maps", "scales",
  "wordcloud", "RColorBrewer"
)

installed_packages <- rownames(installed.packages())
missing_packages <- setdiff(required_packages, installed_packages)

if (length(missing_packages) == 0) {
  message("All required packages are already installed.")
} else {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}
