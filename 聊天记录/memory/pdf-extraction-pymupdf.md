---
name: pdf-extraction-pymupdf
description: "How to extract text from PDFs on this machine — use PyMuPDF, NOT poppler/pdftotext"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 368c3b27-0eab-4403-9ac8-655b9b6a3e1f
  modified: 2026-08-09T10:48:08.386Z
---

To read/extract text from PDFs in this project, use **PyMuPDF (`import fitz`)**, which is already installed in the Anaconda Python (3.13.5). Do NOT rely on poppler's `pdftotext`/`pdfinfo` CLI — they are NOT installed on this machine (Windows 11), which is why earlier PDF-read tool calls failed red.

Quick check: `python -c "import fitz; print(fitz.__doc__)"` (PyMuPDF 1.28.0 / MuPDF 1.29.0).

Reusable helper committed at project root: `pdf_to_text.py`. Examples:
- `python pdf_to_text.py "paper.pdf"` — print all text
- `python pdf_to_text.py "paper.pdf" -p 1-3 -o out.txt` — pages 1-3 to file
- `python pdf_to_text.py *.pdf --outdir extracted` — batch, one .txt per PDF

Extraction verified working on the project's near-field beam-training PDFs (clean CN+EN text, ~6.6k chars/page). Related: [[research-direction-optionB]].
