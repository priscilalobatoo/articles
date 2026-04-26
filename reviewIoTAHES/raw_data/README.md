# Raw bibliographic data

Place the exported database files in this folder before running the pipeline.

Expected filenames:

- `scopus.bib` — Scopus export in BibTeX format.
- `wos.txt` — Web of Science export in plain-text format.
- `ieee.csv` — IEEE Xplore export in CSV format.

These files are intentionally ignored by Git because they may contain database-exported metadata subject to license restrictions. To reproduce the article results, export the same query results from each database and save them with the filenames above.
