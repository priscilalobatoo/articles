# =========================================================
# 06_bibliometric_plots.R
# Publication-ready bibliometric plots and tables
# =========================================================
#
# Inputs
# ------
# processed_data/base_unificada.rds
#
# Outputs
# -------
# outputs/figures/annual_scientific_production.[png|pdf|svg]
# outputs/figures/top_authors.[png|pdf|svg]
# outputs/figures/top_sources.[png|pdf|svg]
# outputs/figures/top_keywords.[png|pdf|svg]
# outputs/figures/keywords_wordcloud.[png|pdf]
# outputs/tables/*.csv and *.xlsx
# =========================================================

library(dplyr)
library(tidyr)
library(stringr)
library(stringi)
library(ggplot2)
library(openxlsx)
library(wordcloud)
library(RColorBrewer)

cat("Generating bibliometric charts...\n")

# ---------------------------------------------------------
# 1. Load final corpus
# ---------------------------------------------------------
if (!exists("base_unificada")) {
  if (!file.exists("processed_data/base_unificada.rds")) {
    stop("processed_data/base_unificada.rds not found. Run 03_deduplication_merge.R first.")
  }
  base_unificada <- readRDS("processed_data/base_unificada.rds")
}

M <- base_unificada

# ---------------------------------------------------------
# 2. Plot settings
# ---------------------------------------------------------
flag_green <- "#009C3B"
light_green <- "#7BC67B"
dark_green <- "#006B2D"

publication_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    axis.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

save_plot_all_formats <- function(plot_object, file_stub, width = 8, height = 5) {
  png_file <- file.path("outputs/figures", paste0(file_stub, ".png"))
  pdf_file <- file.path("outputs/figures", paste0(file_stub, ".pdf"))
  svg_file <- file.path("outputs/figures", paste0(file_stub, ".svg"))

  ggsave(png_file, plot = plot_object, width = width, height = height, dpi = 600, bg = "white")
  ggsave(pdf_file, plot = plot_object, width = width, height = height, device = cairo_pdf)

  grDevices::svg(svg_file, width = width, height = height)
  print(plot_object)
  grDevices::dev.off()
}

# ---------------------------------------------------------
# 3. Helper functions for parsing metadata
# ---------------------------------------------------------
split_semicolon_field <- function(x) {
  x <- x[!is.na(x) & x != ""]
  unlist(str_split(x, ";|,"), use.names = FALSE) %>%
    str_squish() %>%
    .[. != ""]
}

format_author_label <- function(author_name) {
  # Produces labels such as "Y. Li" and "G. Ferrari".
  author_name <- str_squish(author_name)
  author_name <- str_replace_all(author_name, "\\.", "")

  if (is.na(author_name) || author_name == "") return(NA_character_)

  if (str_detect(author_name, ",")) {
    parts <- str_split(author_name, ",", n = 2)[[1]]
    surname <- str_squish(parts[1])
    given_names <- str_squish(parts[2])
  } else {
    tokens <- str_split(author_name, "\\s+")[[1]]
    if (length(tokens) == 1) return(str_to_title(tokens[1]))

    # Bibliographic AU fields often appear as "LI Y" or "FERRARI G".
    if (str_detect(tokens[1], "^[A-ZÀ-Ý-]+$") && all(str_detect(tokens[-1], "^[A-Z]{1,3}$"))) {
      surname <- tokens[1]
      given_names <- paste(tokens[-1], collapse = " ")
    } else {
      surname <- tokens[length(tokens)]
      given_names <- paste(tokens[-length(tokens)], collapse = " ")
    }
  }

  initials <- str_split(given_names, "\\s+")[[1]]
  initials <- initials[initials != ""]
  initials <- paste0(str_sub(initials, 1, 1), ".", collapse = " ")
  paste(initials, str_to_title(surname))
}

# ---------------------------------------------------------
# 4. Annual scientific production
# ---------------------------------------------------------
annual_production <- M %>%
  filter(!is.na(PY_NUM)) %>%
  count(PY_NUM, name = "Publications") %>%
  arrange(PY_NUM)

write.csv(annual_production, "outputs/tables/annual_scientific_production.csv", row.names = FALSE, fileEncoding = "UTF-8")
openxlsx::write.xlsx(annual_production, "outputs/tables/annual_scientific_production.xlsx", overwrite = TRUE)

p_annual <- ggplot(annual_production, aes(x = PY_NUM, y = Publications)) +
  geom_line(linewidth = 1.1, color = flag_green) +
  geom_point(size = 2.5, color = dark_green) +
  geom_text(aes(label = Publications), vjust = -0.6, size = 3.1, color = dark_green) +
  scale_x_continuous(breaks = annual_production$PY_NUM) +
  labs(
    title = "Annual Scientific Production",
    x = "Year",
    y = "Publications"
  ) +
  publication_theme

save_plot_all_formats(p_annual, "annual_scientific_production", width = 8, height = 4.8)

# ---------------------------------------------------------
# 5. Most productive authors
# ---------------------------------------------------------
author_field <- if ("AF" %in% names(M) && any(!is.na(M$AF) & M$AF != "")) M$AF else M$AU

authors_top <- data.frame(AU = split_semicolon_field(author_field)) %>%
  mutate(AU = format_author_label(AU)) %>%
  filter(!is.na(AU), AU != "") %>%
  count(AU, name = "Publications") %>%
  arrange(desc(Publications), AU) %>%
  slice_head(n = 20)

write.csv(authors_top, "outputs/tables/top_authors.csv", row.names = FALSE, fileEncoding = "UTF-8")
openxlsx::write.xlsx(authors_top, "outputs/tables/top_authors.xlsx", overwrite = TRUE)

p_authors <- ggplot(authors_top, aes(x = reorder(AU, Publications), y = Publications)) +
  geom_col(fill = flag_green) +
  coord_flip() +
  geom_text(aes(label = Publications), hjust = -0.15, size = 3.0, color = dark_green) +
  labs(
    title = "Most Productive Authors",
    x = "Author",
    y = "Publications"
  ) +
  publication_theme +
  expand_limits(y = max(authors_top$Publications) * 1.12)

save_plot_all_formats(p_authors, "top_authors", width = 7.5, height = 6)

# ---------------------------------------------------------
# 6. Most relevant publication sources
# ---------------------------------------------------------
sources_top <- M %>%
  filter(!is.na(SO), SO != "") %>%
  mutate(SO = str_squish(str_to_title(SO))) %>%
  count(SO, name = "Publications") %>%
  arrange(desc(Publications), SO) %>%
  slice_head(n = 20)

write.csv(sources_top, "outputs/tables/top_sources.csv", row.names = FALSE, fileEncoding = "UTF-8")
openxlsx::write.xlsx(sources_top, "outputs/tables/top_sources.xlsx", overwrite = TRUE)

p_sources <- ggplot(sources_top, aes(x = reorder(SO, Publications), y = Publications)) +
  geom_col(fill = flag_green) +
  coord_flip() +
  geom_text(aes(label = Publications), hjust = -0.15, size = 2.8, color = dark_green) +
  labs(
    title = "Most Relevant Publication Sources",
    x = "Source",
    y = "Publications"
  ) +
  publication_theme +
  theme(axis.text.y = element_text(size = 8)) +
  expand_limits(y = max(sources_top$Publications) * 1.12)

save_plot_all_formats(p_sources, "top_sources", width = 9, height = 6.2)

# ---------------------------------------------------------
# 7. Most frequent keywords
# ---------------------------------------------------------
keyword_vector <- c(split_semicolon_field(M$DE), split_semicolon_field(M$ID))
keyword_vector <- keyword_vector %>%
  str_to_lower() %>%
  str_squish() %>%
  .[. != ""]

keywords_top <- data.frame(KW = keyword_vector) %>%
  count(KW, name = "Frequency") %>%
  arrange(desc(Frequency), KW) %>%
  slice_head(n = 20)

write.csv(keywords_top, "outputs/tables/top_keywords.csv", row.names = FALSE, fileEncoding = "UTF-8")
openxlsx::write.xlsx(keywords_top, "outputs/tables/top_keywords.xlsx", overwrite = TRUE)

p_keywords <- ggplot(keywords_top, aes(x = reorder(KW, Frequency), y = Frequency)) +
  geom_col(fill = flag_green) +
  coord_flip() +
  geom_text(aes(label = Frequency), hjust = -0.15, size = 2.9, color = dark_green) +
  labs(
    title = "Most Frequent Keywords",
    x = "Keyword",
    y = "Frequency"
  ) +
  publication_theme +
  expand_limits(y = max(keywords_top$Frequency) * 1.12)

save_plot_all_formats(p_keywords, "top_keywords", width = 8, height = 5.8)

# ---------------------------------------------------------
# 8. Keyword word cloud
# ---------------------------------------------------------
# The word cloud is a visual complement to the keyword ranking. PNG and PDF are
# generated directly with base graphics because wordcloud is not a ggplot object.
wordcloud_png <- "outputs/figures/keywords_wordcloud.png"
wordcloud_pdf <- "outputs/figures/keywords_wordcloud.pdf"

png(wordcloud_png, width = 3600, height = 2400, res = 450, bg = "white")
set.seed(123)
wordcloud(
  words = keywords_top$KW,
  freq = keywords_top$Frequency,
  scale = c(4.8, 0.8),
  min.freq = 1,
  random.order = FALSE,
  rot.per = 0.08,
  colors = brewer.pal(8, "Greens")
)
dev.off()

pdf(wordcloud_pdf, width = 10, height = 6.8)
set.seed(123)
wordcloud(
  words = keywords_top$KW,
  freq = keywords_top$Frequency,
  scale = c(4.8, 0.8),
  min.freq = 1,
  random.order = FALSE,
  rot.per = 0.08,
  colors = brewer.pal(8, "Greens")
)
dev.off()

cat("Bibliometric charts generated successfully.\n")
