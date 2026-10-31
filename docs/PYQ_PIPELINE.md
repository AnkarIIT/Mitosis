# NEET PYQ Pipeline

Real previous-year questions extracted from the scanned-downloaded PDFs in
`NEET_PYQ/` into a structured, reviewable JSON bank.

## What exists today

| Stage | Tool | Output |
|---|---|---|
| Layout text | `tools/extract_pyq_text.py` | `outputs/pyq_text/neet_<year>.txt` |
| Parse to MCQs | `tools/parse_pyq_v3.py` | `outputs/pyq_parsed/neet_<year>.json` |
| Shipped asset | (combined in-run) | `assets/questions/pyq_official.json` |

**Current bank: 817 text-complete questions** across 2015–2018 and 2021–2022
(4 options each, subject-tagged). Question *numbering* is per-paper and
faithful to the PDF.

## Honest limitations

1. **`correctAnswer` is null.** No official answer-key source is in the repo.
   Until keys are added these questions are review/practice *content*, not
   auto-gradable MCQs — the app must not score them. Do not fabricate keys.
2. **2019 and 2020 and 2023/2024 are excluded.** 2019's PDF is a solutions
   book, not a question paper; 2020/2023/2024 PDFs are pure scanned images
   (0 extractable chars) and need OCR — out of scope until OCR tooling is added.
3. **Formula-heavy questions are skipped.** Options rendered as vector
   images in the PDF can't be extracted by text means; those rows are
   flagged `incomplete` and dropped from the shipped set (visible per-year in
   `outputs/pyq_parsed/neet_<year>.json` under `total_parsed` vs `complete`).
4. **Cross-column bleed.** Two-column pages occasionally interleave text from
   the neighbouring column (parser chooses the better of two de-column
   strategies per page). Spot-verify before trusting any specific question.

## Rebuilding the bank

```bash
python tools/extract_pyq_text.py     # PDFs -> layout text
python tools/parse_pyq_v3.py         # text -> per-year JSON + asset
```

## Next steps to production-grade

1. Obtain official NTA answer keys (drop `KEY_<year>.pdf` into `NEET_PYQ/`)
   and extend the parser to attach `correctAnswer` by question number.
2. Add OCR (e.g. Tesseract) for 2020/2023/2024 scanned papers.
3. Wire `assets/questions/pyq_official.json` into
   `QuestionRepository.importFromAsset()` **only after** keys exist, so zero
   ungraded questions enter the quiz engine.
