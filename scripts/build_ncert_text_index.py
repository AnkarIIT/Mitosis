#!/usr/bin/env python3
"""Build the NCERT text index used to ground the AI tutor.

Reads the chapter->PDF mapping out of `lib/core/services/ncert_book_catalog.dart`,
extracts the text of every mapped PDF page with pypdf, and writes one compact
JSON file per chapter plus a manifest under `assets/ncert_text/`.

The index is what makes the chat "grounded": the whole chapter text is injected
into the Gemini prompt, so the model can only reason from real NCERT content and
cite PDF page numbers back.

Exit codes:
  0   every chapter extracted above the quality gate
  1   at least one chapter failed (missing PDF, too few words, ...)
Usage: python scripts/build_ncert_text_index.py   (run from the repo root)
"""

import json
import re
import sys
from pathlib import Path

from pypdf import PdfReader

REPO = Path(__file__).resolve().parent.parent
CATALOG = REPO / "lib" / "core" / "services" / "ncert_book_catalog.dart"
OUT_DIR = REPO / "assets" / "ncert_text"
BASE = "assets/ncert_books"

MIN_WORDS = 2000  # a chapter below this is treated as a bad extraction


def parse_catalog() -> dict[str, dict]:
    """Read chapter key -> {pdf path, subject, class level, title} from the Dart source."""
    src = CATALOG.read_text(encoding="utf-8")

    # ---- PDF mapping: 'bio_ch1': '$_base/biology/Biology_Class_11/kebo101.pdf' ----
    pdf_map: dict[str, str] = {}
    for m in re.finditer(
        r"'(bio_ch\d+(?:_\d+)?|chem_ch\d+|phys_ch\d+)':\s*'\$_base/([^']+)'", src
    ):
        pdf_map[m.group(1)] = f"{BASE}/{m.group(2)}"

    # ---- Book entries with titles: add('Biology', 'Class 11', 'Biologi...',  ----
    #          ...   'kebo101.pdf', 1, 'The Living World')
    entries: dict[str, dict] = {}
    for m in re.finditer(
        r"add\(\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']+)',\s*(\d+),\s*'([^']+)'\s*,?",
        src,
    ):
        subject, class_level, book_name, file_name, number, title = m.groups()
        asset_path = f"{BASE}/{subject.lower()}/{book_name}/{file_name}"
        entries[asset_path] = {
            "subject": subject,
            "className": class_level,
            "title": title,
            "chapterNumber": int(number),
        }

    chapters = []
    for key in pdf_map:
        meta = entries.get(pdf_map[key])
        if meta is None:
            raise SystemExit(f"chapter {key}: no book entry for {pdf_map[key]}")
        chapters.append({"chapterId": key, "pdf": pdf_map[key], **meta})

    chapters.sort(key=lambda c: (c["subject"], c["className"], c["pdf"]))
    return chapters


def clean_page(text: str) -> str:
    """Normalize pypdf artifacts so the model reads coherent sentences."""
    if not text:
        return ""
    # Flatten everything to single spaces per paragraph so tokens are not wasted
    # on broken lines. Keeps in-text formatting loss acceptable: the model only
    # needs meaning, not layout.
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\s*\n\s*", "\n", text)
    text = re.sub(r"\n{2,}", "\n\n", text)
    return text.strip()


def extract_pdf(path: Path) -> list[str]:
    reader = PdfReader(str(path))
    pages = []
    for i, page in enumerate(reader.pages, start=1):
        try:
            text = page.extract_text() or ""
        except Exception as exc:  # single bad page must not kill the chapter
            print(f"    page {i}: extraction failed ({exc}) — kept empty", file=sys.stderr)
            text = ""
        pages.append(clean_page(text))
    return pages


def main() -> int:
    chapters = parse_catalog()
    print(f"mapped chapters in catalog: {len(chapters)}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    manifest = {}
    failures = []

    for ch in chapters:
        pdf = REPO / ch["pdf"]
        if not pdf.exists():
            failures.append(f"{ch['chapterId']}: missing PDF {ch['pdf']}")
            continue

        pages = extract_pdf(pdf)
        words = sum(len((p or "").split()) for p in pages)
        if words < MIN_WORDS:
            failures.append(
                f"{ch['chapterId']}: only {words} words extracted (< {MIN_WORDS});"
                " PDF may be scanned/mangled"
            )
            continue

        payload = {
            "chapterId": ch["chapterId"],
            "subject": ch["subject"],
            "className": ch["className"],
            "title": ch["title"],
            "pdf": ch["pdf"],
            "wordCount": words,
            "pageCount": len(pages),
            "pages": [{"n": i, "text": t} for i, t in enumerate(pages, start=1)],
        }
        out = OUT_DIR / f"{ch['chapterId']}.json"
        out.write_text(
            json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
        manifest[ch["chapterId"]] = {
            "file": f"assets/ncert_text/{out.name}",
            "title": ch["title"],
            "subject": ch["subject"],
            "className": ch["className"],
            "words": words,
        }
        print(f"  {ch['chapterId']:<13} {ch['title'][:44]:<44} {words:>6} words, {len(pages)} pages")

    (OUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    kb = sum(f.stat().st_size for f in OUT_DIR.glob("*.json")) / 1024
    print(f"\nindex written to {OUT_DIR} — {kb:.0f} KB total")

    if failures:
        print("\nFAILED chapters:")
        for f in failures:
            print(f"  {f}")
        return 1
    print("\nall chapters passed the quality gate")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
