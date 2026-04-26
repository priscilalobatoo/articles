# Reproducible Pipeline for the IoT Architectures and Hybrid Energy Systems Review

This repository contains the R scripts used to reproduce the bibliometric workflow, adapted ProKnow-C prioritization, and technical synthesis reported in the article:

**A Systematic Review and Bibliometric Analysis of IoT Architectures for Hybrid Energy Systems**

The final article uses a **top 10 prioritized studies** strategy for the technical comparison and architectural taxonomy.

---

## 1. Methodological overview

The workflow follows four complementary stages:

1. **PRISMA-based screening**  
   Records retrieved from Web of Science, IEEE Xplore, and Scopus are cleaned, temporally filtered, deduplicated, and screened according to the article's inclusion and exclusion criteria.

2. **Bibliometric processing**  
   The deduplicated bibliometric corpus is analyzed using R and the `bibliometrix` package. The generated indicators include annual scientific production, most productive authors, publication sources, keyword frequency, and geographical distribution.

3. **Adapted ProKnow-C prioritization**  
   A relevance score is computed from thematic adherence, citation support, and publication recency. The process generates a portfolio of 104 prioritized studies.

4. **Technical synthesis**  
   From the ProKnow-C portfolio, the **top 10 prioritized studies** are used to generate:
   - the technical comparison table;
   - the architectural taxonomy of IoT architectures for hybrid energy systems.

---

## 2. Repository structure

```text
publication_ready_pipeline/
│
├── README.md
├── 00_run_pipeline.R
├── commands.txt
├── references_cleaned.bib
├── .gitignore
│
├── data/
│   └── raw/
│       └── .gitkeep
│
├── processed_data/
│   └── .gitkeep
│
├── figures/
│   └── .gitkeep
│
├── tables/
│   └── .gitkeep
│
└── proknowc/
    ├── 00_proknowc.R
    │
    ├── processed_data/
    │   └── .gitkeep
    │
    ├── proknowc_outputs/
    │   └── .gitkeep
    │
    └── proknowc_analysis/
        ├── 00_run_proknowc_analysis.R
        ├── 01_generate_technical_comparison_table.R
        ├── 02_generate_architecture_taxonomy_table.R
        │
        └── proknowc_analysis_outputs/
            └── .gitkeep
```

---

## 3. Required software

The scripts were designed for R/RStudio. The following R packages are used:

```r
bibliometrix
dplyr
readr
stringr
tidyr
ggplot2
forcats
countrycode
maps
scales
tibble
```

The scripts automatically attempt to install missing packages.

---

## 4. Input data

Place raw exported bibliographic files in:

```text
data/raw/
```

Supported extensions include:

```text
.bib
.bibtex
.csv
.txt
.ris
```

Recommended file naming convention:

```text
data/raw/scopus_export.bib
data/raw/web_of_science_export.txt
data/raw/ieee_export.csv
```

The script attempts to infer the database source from the file name.

> Raw exports from commercial databases may be subject to redistribution restrictions. For this reason, this repository is structured to host scripts and processed outputs, while users may need to provide their own raw exports.

---

## 5. Running the full bibliometric pipeline

### User-specific Windows context

```r
setwd("C:/Users/elenp/Downloads/publication_ready_pipeline")
getwd()
source("00_run_pipeline.R")
```

### Generic context

```r
setwd("C:/home/user/publication_ready_pipeline")
getwd()
source("00_run_pipeline.R")
```

The script generates outputs in:

```text
processed_data/
figures/
tables/
proknowc/processed_data/
```

---

## 6. Running ProKnow-C and technical synthesis

After running `00_run_pipeline.R`, run:

### User-specific Windows context

```r
setwd("C:/Users/elenp/Downloads/publication_ready_pipeline/proknowc/proknowc_analysis")
getwd()
source("00_run_proknowc_analysis.R")
```

### Generic context

```r
setwd("C:/home/user/publication_ready_pipeline/proknowc/proknowc_analysis")
getwd()
source("00_run_proknowc_analysis.R")
```

The script runs:

```r
source("../00_proknowc.R")
source("01_generate_technical_comparison_table.R")
source("02_generate_architecture_taxonomy_table.R")
```

Generated outputs are saved in:

```text
proknowc/proknowc_outputs/
proknowc/proknowc_analysis/proknowc_analysis_outputs/
```

---

## 7. Expected outputs

Main bibliometric outputs:

```text
processed_data/integrated_raw_database.csv
processed_data/base_limpa_temporal_filter.csv
processed_data/base_limpa.csv
processed_data/bibliometric_corpus_2016_2026_deduplicated.csv
```

Main tables:

```text
tables/annual_scientific_production.csv
tables/most_productive_authors.csv
tables/publication_sources.csv
tables/keyword_frequency.csv
tables/publications_by_country.csv
tables/pipeline_run_summary.csv
```

Main figures:

```text
figures/annual_scientific_production.png
figures/annual_scientific_production.pdf
figures/top_authors.png
figures/top_authors.pdf
figures/top_sources.png
figures/top_sources.pdf
figures/top_keywords.png
figures/top_keywords.pdf
figures/publications_by_country_map.png
figures/publications_by_country_map.pdf
```

ProKnow-C outputs:

```text
proknowc/proknowc_outputs/proknowc_ranked_all_records.csv
proknowc/proknowc_outputs/proknowc_prioritized_portfolio_104_records.csv
proknowc/proknowc_outputs/top10_proknowc_prioritized_articles.csv
proknowc/proknowc_outputs/top10_proknowc_table_for_article.csv
```

Technical synthesis outputs:

```text
proknowc/proknowc_analysis/proknowc_analysis_outputs/top10_technical_comparison_table.csv
proknowc/proknowc_analysis/proknowc_analysis_outputs/top10_technical_comparison_table_latex_rows.tex
proknowc/proknowc_analysis/proknowc_analysis_outputs/iot_architecture_taxonomy_top10.csv
proknowc/proknowc_analysis/proknowc_analysis_outputs/iot_architecture_taxonomy_top10_latex_rows.tex
```

---

## 8. Article consistency notes

The current article uses:

- PRISMA-based screening;
- a bibliometric corpus for quantitative indicators;
- an adapted ProKnow-C portfolio of 104 prioritized studies;
- 81 full texts retrieved through Zotero;
- the **top 10 prioritized studies** for technical comparison and taxonomy.

The former top 20 strategy and the isolated 2026 study were removed from the final technical synthesis.

---

## 9. Citation and BibTeX file

The file `references_cleaned.bib` contains only the references used in the current article version after removing unused entries.

---

## 10. Reproducibility checklist

Before uploading to GitHub, verify that:

- [ ] raw data files are not uploaded if redistribution is not permitted;
- [ ] `data/raw/` contains only `.gitkeep` or permitted sample files;
- [ ] all scripts refer to `top10`, not `top20`;
- [ ] the article tables match the generated CSV outputs;
- [ ] the GitHub link in the article points to the correct repository path;
- [ ] no unused `.bib` entries remain in the final bibliography.
