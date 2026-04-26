# =========================================================
# 08_country_analysis_map.R
# Country normalization, publication counts, and world map
# =========================================================
#
# Inputs
# ------
# processed_data/base_unificada.rds
#
# Outputs
# -------
# outputs/tables/publications_by_country.csv/.xlsx
# outputs/figures/publications_by_country_map.[png|pdf|svg]
# =========================================================

library(dplyr)
library(stringr)
library(stringi)
library(ggplot2)
library(maps)
library(openxlsx)

cat("Starting country analysis and map generation...\n")

# ---------------------------------------------------------
# 1. Load final corpus
# ---------------------------------------------------------
if (!file.exists("processed_data/base_unificada.rds")) {
  stop("processed_data/base_unificada.rds not found. Run 03_deduplication_merge.R first.")
}

M <- readRDS("processed_data/base_unificada.rds")

# ---------------------------------------------------------
# 2. Country aliases and normalization
# ---------------------------------------------------------
# The aliases below correct variants such as:
# - "India" + "India." -> India
# - "Peoples R China." + "China" -> China
# - "Italy" + "Italy." -> Italy
# and other frequent variants found in bibliographic affiliation fields.
country_alias <- c(
  "usa" = "USA", "us" = "USA", "u s a" = "USA", "united states" = "USA", "united states of america" = "USA",
  "china" = "China", "peoples r china" = "China", "people r china" = "China", "pr china" = "China", "p r china" = "China", "peoples republic of china" = "China",
  "india" = "India", "italy" = "Italy", "brazil" = "Brazil", "brasil" = "Brazil",
  "uk" = "UK", "united kingdom" = "UK", "england" = "UK", "scotland" = "UK", "wales" = "UK",
  "germany" = "Germany", "deutschland" = "Germany", "france" = "France", "spain" = "Spain", "espana" = "Spain",
  "canada" = "Canada", "australia" = "Australia", "japan" = "Japan", "south korea" = "South Korea", "korea" = "South Korea", "republic of korea" = "South Korea",
  "ireland" = "Ireland", "netherlands" = "Netherlands", "the netherlands" = "Netherlands", "portugal" = "Portugal", "mexico" = "Mexico",
  "turkey" = "Turkey", "turkiye" = "Turkey", "iran" = "Iran", "saudi arabia" = "Saudi Arabia", "united arab emirates" = "United Arab Emirates", "uae" = "United Arab Emirates",
  "singapore" = "Singapore", "malaysia" = "Malaysia", "indonesia" = "Indonesia", "pakistan" = "Pakistan", "bangladesh" = "Bangladesh",
  "russia" = "Russia", "russian federation" = "Russia", "poland" = "Poland", "romania" = "Romania", "sweden" = "Sweden", "norway" = "Norway", "finland" = "Finland", "denmark" = "Denmark",
  "switzerland" = "Switzerland", "austria" = "Austria", "belgium" = "Belgium", "greece" = "Greece", "egypt" = "Egypt", "south africa" = "South Africa", "nigeria" = "Nigeria", "morocco" = "Morocco",
  "chile" = "Chile", "argentina" = "Argentina", "colombia" = "Colombia", "peru" = "Peru", "ecuador" = "Ecuador"
)

clean_country_key <- function(x) {
  x <- as.character(x)
  x <- stringi::stri_trans_general(x, "Latin-ASCII")
  x <- str_to_lower(x)
  x <- str_replace_all(x, "[\\[\\]\\(\\)]", " ")
  x <- str_replace_all(x, "[.;:,]+$", "")
  x <- str_replace_all(x, "[^a-z0-9 ]+", " ")
  str_squish(x)
}

extract_countries_from_affiliation <- function(affiliation) {
  if (is.na(affiliation) || affiliation == "") return(character(0))

  text <- clean_country_key(affiliation)
  parts <- unlist(str_split(text, ";|,"), use.names = FALSE)
  parts <- clean_country_key(parts)

  # Exact matching on affiliation segments is preferred.
  exact_matches <- country_alias[parts]
  exact_matches <- unname(exact_matches[!is.na(exact_matches)])

  # Fallback: detect country aliases appearing anywhere in the affiliation string.
  pattern_matches <- unname(country_alias[vapply(names(country_alias), function(alias) {
    str_detect(text, paste0("\\b", str_replace_all(alias, " ", "\\\\s+"), "\\b"))
  }, logical(1))])

  unique(c(exact_matches, pattern_matches))
}

# ---------------------------------------------------------
# 3. Count publications by country
# ---------------------------------------------------------
country_list <- lapply(M$C1, extract_countries_from_affiliation)

country_table <- data.frame(Country = unlist(country_list, use.names = FALSE)) %>%
  filter(!is.na(Country), Country != "") %>%
  count(Country, name = "Publications") %>%
  arrange(desc(Publications), Country)

write.csv(country_table, "outputs/tables/publications_by_country.csv", row.names = FALSE, fileEncoding = "UTF-8")
openxlsx::write.xlsx(country_table, "outputs/tables/publications_by_country.xlsx", overwrite = TRUE)

# ---------------------------------------------------------
# 4. Build world map
# ---------------------------------------------------------
world <- map_data("world")

map_country_names <- function(x) {
  recode(x,
    "USA" = "USA",
    "UK" = "UK",
    "South Korea" = "South Korea",
    .default = x
  )
}

country_table <- country_table %>%
  mutate(region = map_country_names(Country))

world_counts <- world %>%
  left_join(country_table, by = "region")

p_map <- ggplot(world_counts, aes(long, lat, group = group)) +
  geom_polygon(aes(fill = Publications), color = "white", linewidth = 0.1) +
  scale_fill_gradient(low = "#D8F0D2", high = "#006B2D", na.value = "grey92") +
  labs(
    title = "Global Distribution of Publications by Country",
    x = NULL,
    y = NULL,
    fill = "Publications"
  ) +
  coord_fixed(1.3) +
  theme_void(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    legend.position = "bottom"
  )

# Save in high-resolution formats for article use.
ggsave("outputs/figures/publications_by_country_map.png", p_map, width = 10, height = 5.8, dpi = 600, bg = "white")
ggsave("outputs/figures/publications_by_country_map.pdf", p_map, width = 10, height = 5.8, device = cairo_pdf)
svg("outputs/figures/publications_by_country_map.svg", width = 10, height = 5.8)
print(p_map)
dev.off()

cat("Country analysis completed successfully.\n")
