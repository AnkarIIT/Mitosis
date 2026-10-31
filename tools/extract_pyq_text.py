"""Extract layout-preserved text from NEET PYQ PDFs.

Uses pypdf 6.x layout mode, which keeps the two-column NTA paper structure
more faithfully than the default extraction. Output goes to outputs/pyq_text/
one .txt per year, for parsing and manual verification.

Usage:
    python tools/extract_pyq_text.py           # all digital years
    python tools/extract_pyq_text.py 2022      # single year
"""
import os
import sys

from pypdf import PdfReader

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PDF_DIR = os.path.join(ROOT, "NEET_PYQ")
OUT_DIR = os.path.join(ROOT, "outputs", "pyq_text")

# Years whose PDFs contain digital text (2020/2023/2024 are scanned images).
DIGITAL_YEARS = [2015, 2016, 2017, 2018, 2019, 2021, 2022]


def extract_year(year: int) -> str:
    reader = PdfReader(os.path.join(PDF_DIR, f"NEET_{year}.pdf"))
    pages = []
    for page in reader.pages:
        try:
            pages.append(page.extract_text(extraction_mode="layout") or "")
        except Exception as e:  # noqa: BLE001 — keep going past bad pages
            pages.append(f"[EXTRACTION ERROR page: {e}]")
    return "\n\n===== PAGE BREAK =====\n\n".join(pages)


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    years = [int(a) for a in sys.argv[1:]] or DIGITAL_YEARS
    for year in years:
        text = extract_year(year)
        out_path = os.path.join(OUT_DIR, f"neet_{year}.txt")
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(text)
        print(f"{year}: {len(text)} chars -> {out_path}")


if __name__ == "__main__":
    main()
