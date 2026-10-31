"""Parse NEET PYQ layout text (outputs/pyq_text/neet_YYYY.txt) into structured MCQs.

Pipeline per paper:
  1. De-column each page: NTA papers are two-column; layout text preserves the
     column offset, so each line is split at the widest internal space run and
     the left-column block is emitted before the right-column block. This
     restores natural reading order.
  2. Section detection via heading lines (PHYSICS / CHEMISTRY / BOTANY ...).
  3. Question segmentation on numbered markers (``12.`` style at line starts).
  4. Option extraction for ``(1)/(2)/...`` and ``1)/2)/...`` marker styles.

Honest limitations (recorded in the coverage report):
  * Questions whose formulas were vector images in the source PDF have blank
    option bodies — flagged ``incomplete: true`` and never auto-shipped.
  * OCR/lay-out artefacts (e.g. stray ``R6`` tokens) are stripped best-effort.
  * Answer keys are NOT in this repo; ``correctAnswer`` is null until a key
    source is added (place key PDFs in NEET_PYQ/ and run parse with keys).

Usage:
    python tools/parse_pyq.py                 # all years
    python tools/parse_pyq.py 2022            # single year
"""
import json
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEXT_DIR = os.path.join(ROOT, "outputs", "pyq_text")
OUT_DIR = os.path.join(ROOT, "outputs", "pyq_parsed")

SECTION_RE = re.compile(r"(?im)^[\s|\[\](]*(physics|chemistry|botany|zoology|biology)\b\s*[^\n]{0,30}$")
QNUM_RE = re.compile(r"(?m)^\s*(\d{1,3})\s*\.\s+")
OPT_RE = re.compile(r"(?:\((\d)\)\s*|\s(\d)\)\s+)")
STRAY_TOKENS = re.compile(r"(?m)(R6|RR?6?)\s*$")

MAX_Q = 205  # NEET has 180-200 questions; allow slack for section headers.


def widest_gap_splits(line: str) -> tuple[str, str] | None:
    """Split a layout line into (left, right) at the widest run of spaces."""
    best = None  # (start,end,len)
    run_start = None
    for i, ch in enumerate(line):
        if ch == " ":
            if run_start is None:
                run_start = i
        else:
            if run_start is not None and (best is None or i - run_start > best[2]):
                best = (run_start, i, i - run_start)
            run_start = None
    if run_start is not None and run_start > 0 and (best is None or len(line) - run_start > best[2]):
        best = (run_start, len(line), len(line) - run_start)
    if not best or best[2] < 10:
        return None
    return line[: best[0]].rstrip(), line[best[1] :].lstrip()


def de_column(page_text: str) -> str:
    """Emit left-column block then right-column block, preserving order."""
    left, right = [], []
    for line in page_text.splitlines():
        parts = widest_gap_splits(line)
        if parts is None:
            # A full-width line: keep in the left (main) stream.
            left.append(line)
            continue
        l, r = parts
        if l:
            left.append(l)
        if r:
            right.append(r)
    return "\n".join(left + right)


def parse_paper(year: int) -> dict:
    raw = open(os.path.join(TEXT_DIR, f"neet_{year}.txt"), encoding="utf-8").read()
    pages = raw.split("===== PAGE BREAK =====")
    linear = "\n".join(de_column(p) for p in pages)

    # Cut leading instructions before the first section heading / question 1.
    # Subject table columnwise, tracking section per question marker.
    sections: list[tuple[str, int]] = []
    for m in SECTION_RE.finditer(linear):
        sections.append((m.group(1).title(), m.start()))

    questions = []
    last_pos: dict[str, str] = {}
    spans = [(s, e[1] if False else 0) for s, e in []]  # placeholder, unused

    # Question spans: list of (qnum, start). End = next start.
    qstarts = [(m.group(1), m.start(), m.end()) for m in QNUM_RE.finditer(linear)]

    for idx, (qnum, start, end_marker) in enumerate(qstarts):
        end = qstarts[idx + 1][1] if idx + 1 < len(qstarts) else len(linear)
        body = linear[start:end]

        # Section for this question = last section heading before its start.
        subj = None
        for name, pos in sections:
            if pos < start:
                subj = name
            else:
                break
        subj = subj or "Unknown"

        # Options: split body by option markers keeping order.
        opt_iter = list(OPT_RE.finditer(body))
        question_text = body[: opt_iter[0].start()] if opt_iter else body
        question_text = STRAY_TOKENS.sub("", question_text).strip()
        question_text = re.sub(r"\s+", " ", question_text)

        options: dict[str, str] = {}
        for i, om in enumerate(opt_iter):
            num = om.group(1) or om.group(2)
            if num is not None and 1 <= int(num) <= 4:
                end_o = opt_iter[i + 1].start() if i + 1 < len(opt_iter) else len(body)
                text = body[om.end() : end_o]
                text = STRAY_TOKENS.sub("", text).strip()
                text = re.sub(r"\s+", " ", text)
                # numeric option bodies (e.g. "5 m") are fine; empty => image
                options.setdefault(num, text)

        complete = len(options) == 4 and all(options.get(str(n), "").strip() for n in (1, 2, 3, 4))
        complete = complete and len(question_text) > 20

        questions.append(
            {
                "year": year,
                "subject": subj,
                "qnum": int(qnum),
                "question": question_text,
                "options": options,
                "incomplete": not complete,
                "correctAnswer": None,  # answer key source pending (see module docstring)
            }
        )
    last_pos = {}

    # Deduplicate repeated qnums (cover pages / repeated footers): keep the
    # longest-body variant per (subject-or-none, qnum).
    best: dict[tuple[int, int], dict] = {}
    for q in questions:
        key = (q["qnum"], q["subject"])
        cur = best.get(key)
        if cur is None or len(q["question"]) + len(json.dumps(q["options"])) > len(cur["question"]) + len(json.dumps(cur["options"])):
            best[key] = q

    final = sorted(best.values(), key=lambda q: (q["subject"], q["qnum"]))
    complete_n = sum(1 for q in final if not q["incomplete"])
    return {
        "year": year,
        "total_parsed": len(final),
        "complete": complete_n,
        "sections_reported": Counter(q["subject"] for q in final).most_common(),
        "questions": final,
    }


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    years = [int(a) for a in sys.argv[1:]] or [2015, 2016, 2017, 2018, 2019, 2021, 2022]
    summary = []
    for year in years:
        paper = parse_paper(year)
        out = os.path.join(OUT_DIR, f"neet_{year}.json")
        with open(out, "w", encoding="utf-8") as f:
            json.dump(paper, f, ensure_ascii=False, indent=1)
        print(
            f"{year}: parsed {paper['total_parsed']} questions, "
            f"{paper['complete']} complete -> {out}"
        )
        summary.append(f"{year}: {paper['total_parsed']} parsed / {paper['complete']} complete")
    print("\n".join(summary))


if __name__ == "__main__":
    main()
