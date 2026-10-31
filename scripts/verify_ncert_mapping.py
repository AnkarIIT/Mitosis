"""Verify the NCERT chapter -> bundled PDF mapping.

Compares every title in `NcertBookCatalog._buildEntries` against the real title
stored inside the PDF (metadata `/Title`, falling back to the printed chapter
heading), and flags mappings that point at files which do not exist.

Why this exists: the PDF filenames follow NCERT's *rationalised* numbering
(2023 onwards) while the app chapter ids follow the older numbering. That
mismatch silently served students the wrong chapter for a year.

Run:  python scripts/verify_ncert_mapping.py [--repo PATH]
Exit: 0 = clean, 1 = problems found.
"""
from __future__ import annotations

import argparse
import difflib
import re
import sys
from pathlib import Path

from pypdf import PdfReader

# PDFs whose embedded metadata is wrong/truncated in the source file itself.
# lebo107.pdf ships the title of its unit opener ("Human Welfare") instead of
# the chapter name, so there is nothing to compare against programmatically.
METADATA_UNRELIABLE = {
    "lebo107.pdf": "metadata contains the unit-opener title, chapter is "
                   "Human Health and Disease (verified from page 1 heading)",
}

# PDFs with neither metadata nor an extractable heading. Confirmed once by hand
# against page 1 of the file; re-check by opening the PDF if the mapping moves.
MANUAL_CHECKS = {
    "kech101.pdf": "SOME BASIC CONCEPTS OF CHEMISTRY",
    "kech102.pdf": "structure of atom",
}

THRESHOLD = 0.75


def norm(text: str) -> str:
    text = text.lower().replace("&", " and ")
    return re.sub(r"[^a-z0-9]+", " ", text).strip()


def similarity(a: str, b: str) -> float:
    na, nb = norm(a), norm(b)
    seq = difflib.SequenceMatcher(None, na, nb).ratio()
    sa, sb = set(na.split()), set(nb.split())
    jaccard = len(sa & sb) / len(sa | sb) if (sa | sb) else 1.0
    return max(seq, jaccard)


def parse_catalog(dart: str):
    block = re.search(r"_appChapterPdf = \{(.*?)\n  \};", dart, re.S)
    if block is None:
        raise SystemExit("could not find the _appChapterPdf block")
    mapping = re.findall(r"'(\w+)': '\$_base/([^']+)'", block.group(1))

    entries = {}
    for m in re.finditer(
        r"add\(\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*(\d+),\s*'([^']+)',?\s*\)",
        dart,
        re.S,
    ):
        subject, cls, book, file, num, title = m.groups()
        entries[(book, file)] = (int(num), title)
    return mapping, entries


def printed_heading(reader: PdfReader) -> str:
    for i in range(min(4, len(reader.pages))):
        try:
            text = reader.pages[i].extract_text() or ""
        except Exception:
            continue
        lines = [l.strip() for l in text.splitlines() if l.strip()]
        # "CHAPTER FOUR" / "LAWS OF MOTION 51"
        for a, b in zip(lines, lines[1:]):
            if re.fullmatch(r"[A-Z][A-Z ,&'\-]{8,}", a) and re.fullmatch(r"\d{1,3}", b):
                return a
        for line in lines:
            m = re.fullmatch(r"([A-Z][A-Z ,&'\-]{8,})\s+(\d{1,3})", line)
            if m and not m.group(1).startswith("CHAPTER"):
                return m.group(1)
    return ""


WORDS = {
    "ONE": 1, "TWO": 2, "THREE": 3, "FOUR": 4, "FIVE": 5, "SIX": 6,
    "SEVEN": 7, "EIGHT": 8, "NINE": 9, "TEN": 10, "ELEVEN": 11,
    "TWELVE": 12, "THIRTEEN": 13, "FOURTEEN": 14, "FIFTEEN": 15,
    "SIXTEEN": 16, "SEVENTEEN": 17, "EIGHTEEN": 18, "NINETEEN": 19,
    "TWENTY": 20,
}


def printed_chapter_number(reader: PdfReader) -> int | None:
    """Chapter number printed in the PDF header, independent of the title.

    Works when the title itself is not text-extractable (e.g. kebo101.pdf),
    and still catches off-by-one shifts, which is the bug this guards against.
    """
    for i in range(min(6, len(reader.pages))):
        try:
            text = reader.pages[i].extract_text() or ""
        except Exception:
            continue
        for line in text.splitlines():
            # Only a standalone "CHAPTER 8" / "CHAPTER EIGHT" line counts;
            # body text like "as seen in Chapter 9" must not match.
            m = re.fullmatch(r"\s*CHAPTER\s+(\d{1,2}|[A-Z]{3,})\s*", line, re.I)
            if not m:
                continue
            token = m.group(1).upper()
            if token.isdigit():
                return int(token)
            if token in WORDS:
                return WORDS[token]
    return None


def pdf_title(path: Path) -> tuple[str, str]:
    """Return (title, source) where source is 'metadata' | 'heading' | ''."""
    reader = PdfReader(str(path))
    if path.name in METADATA_UNRELIABLE:
        return "", "unreliable-metadata"
    meta = ((reader.metadata or {}).get("/Title") or "").strip()
    meta = re.sub(r"\.pmd$", "", meta, flags=re.I).strip()
    if path.name in MANUAL_CHECKS:
        return "", "manual"
    looks_garbage = (
        not meta
        or len(meta) < 5
        or re.fullmatch(r"ch(apter)?[- ]?\d+", meta, re.I)
        or re.search(r"[:\\/]|\.indd|textbook", meta, re.I)
    )
    if not looks_garbage:
        return meta, "metadata"
    heading = printed_heading(reader)
    return (heading, "heading") if heading else ("", "")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=str(Path(__file__).resolve().parents[1]))
    args = ap.parse_args()

    root = Path(args.repo)
    catalog = root / "lib/core/services/ncert_book_catalog.dart"
    mapping, entries = parse_catalog(catalog.read_text(encoding="utf-8"))

    problems, skipped = [], []
    seen: dict[str, str] = {}

    for chapter_key, rel in mapping:
        book, file = rel.split("/")[1], rel.split("/")[-1]
        path = root / "assets/ncert_books" / rel
        declared = entries.get((book, file))

        if not path.exists():
            problems.append(("MISSING PDF", chapter_key, rel, declared[1] if declared else "?"))
            continue
        if declared is None:
            problems.append(("NO CATALOG ENTRY", chapter_key, rel, "-"))
            continue
        if rel in seen:
            problems.append(("DUPLICATE FILE", chapter_key, rel, f"also used by {seen[rel]}"))
        seen[rel] = chapter_key

        actual, source = pdf_title(path)
        if source == "unreliable-metadata":
            skipped.append((chapter_key, rel, METADATA_UNRELIABLE[file]))
            continue
        if source == "manual":
            skipped.append((chapter_key, rel,
                            f"no extractable title; page 1 read by hand: {MANUAL_CHECKS[file]!r}"))
            continue
        if not actual:
            number = printed_chapter_number(PdfReader(str(path)))
            if number is not None and number == declared[0]:
                skipped.append((chapter_key, rel,
                                f"title not text-extractable, but PDF is chapter {number} "
                                f"as declared"))
            elif number is not None:
                problems.append(
                    ("WRONG CHAPTER", chapter_key, rel,
                     f"declared chapter {declared[0]} ('{declared[1]}') but PDF is chapter {number}")
                )
            else:
                problems.append(("TITLE UNREADABLE", chapter_key, rel, declared[1]))
            continue

        score = similarity(actual, declared[1])
        if score < THRESHOLD:
            problems.append(
                ("MISMATCH", chapter_key, rel,
                 f"declared '{declared[1]}' but PDF says '{actual}' ({score:.0%}, via {source})")
            )

    print(f"mappings={len(mapping)}  problems={len(problems)}  skipped={len(skipped)}\n")
    for kind, key, rel, detail in problems:
        print(f"{kind:<16} {key:<14} {rel}\n{'':<33}{detail}")
    for key, rel, why in skipped:
        print(f"{'SKIPPED':<16} {key:<14} {rel}\n{'':<33}{why}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
