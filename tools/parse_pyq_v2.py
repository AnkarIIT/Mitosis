"""Parse NEET PYQ layout text into structured MCQs (v2).

v2 refinements over tools/parse_pyq.py:
  * Per-page column-seam detection: the modal gap position of a page is the
    seam; lines are then classified left / right / splitting precisely.
  * Section headings match the actual NTA format
    ("Section-A (Physics)", "Section B (Biology : Zoology)", ...).

Honest limitations (see parse_pyq.py docstring as well):
  * Questions whose formulas were vector images carry blank/incomplete
    options -> flagged incomplete, excluded from the shipped set.
  * ``correctAnswer`` stays null until an answer-key source is provided.
"""
import json
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEXT_DIR = os.path.join(ROOT, "outputs", "pyq_text")
OUT_DIR = os.path.join(ROOT, "outputs", "pyq_parsed")

QNUM_RE = re.compile(r"(?m)^\s*(\d{1,3})\s*\.\s+")
OPT_RE = re.compile(r"(?:\((\d)\)\s*|\s(\d)\)\s+)")
STRAY_TOKENS = re.compile(r"(?m)(R6)\s*$")


def _runs_of_spaces(line: str):
    runs = []
    start = None
    for i, ch in enumerate(line):
        if ch == " ":
            if start is None:
                start = i
        else:
            if start is not None:
                runs.append((start, i))
            start = None
    if start is not None:
        runs.append((start, len(line)))
    return runs


def detect_seam(lines: list[str]) -> int | None:
    """Modal start position of wide (>=8 spaces) internal gaps = the seam."""
    votes = Counter()
    for line in lines:
        for s, e in _runs_of_spaces(line):
            if s > 0 and (e - s) >= 8:
                votes[s] += 1
    if not votes:
        return None
    return votes.most_common(1)[0][0]


def de_column_page(page_text: str) -> str:
    lines = page_text.splitlines()
    seam = detect_seam(lines)
    if seam is None:
        return page_text

    left, right = [], []
    for line in lines:
        first_non_space = len(line) - len(line.lstrip())
        candidates = [(s, e) for s, e in _runs_of_spaces(line) if s > 0 and (e - s) >= 6]
        candidates.sort(key=lambda se: abs(se[0] - seam))
        if first_non_space > seam - 20:
            # Entire line is already in the right column.
            right.append(line.lstrip())
            continue
        if candidates:
            s, e = candidates[0]
            if s < seam - 12 and s > 20:
                # A real mid-line gap (the two columns).
                l, r = line[:s].rstrip(), line[e:].lstrip()
                if l:
                    left.append(l)
                if r:
                    right.append(r)
                continue
        left.append(line)
    return "\n".join(left + right)


def parse_paper(year: int) -> dict:
    raw = open(os.path.join(TEXT_DIR, f"neet_{year}.txt"), encoding="utf-8").read()
    pages = raw.split("===== PAGE BREAK =====")
    linear = "\n".join(de_column_page(p) for p in pages)

    sections: list[tuple[str, int]] = []
    for m in re.finditer(r"(?i)Section\s*-?\s*[AB]?\s*\(([^)]{0,30})\)", linear):
        raw_name = re.sub(r"[\s:()]+", "", m.group(1))
        if raw_name in ("BiologyBotany", "Biology:Botany"):
            name = "Botany"
        elif raw_name in ("BiologyZoology", "Biology:Zoology"):
            name = "Zoology"
        elif raw_name in ("Biology",):
            name = "Biology"
        else:
            name = raw_name.title()
        sections.append((name, m.start()))

    qstarts = [(m.group(1), m.start()) for m in QNUM_RE.finditer(linear)]
    parsed = []
    for idx, (qnum, start) in enumerate(qstarts):
        end = qstarts[idx + 1][1] if idx + 1 < len(qstarts) else len(linear)
        body = linear[start:end]

        subj = None
        for name, pos in sections:
            if pos < start:
                subj = name
            else:
                break
        subj = subj or "Unknown"

        opt_iter = list(OPT_RE.finditer(body))
        question_text = body[: opt_iter[0].start()] if opt_iter else body
        question_text = STRAY_TOKENS.sub("", question_text).strip()
        question_text = re.sub(r"\s+", " ", question_text)

        options: dict[str, str] = {}
        for i, om in enumerate(opt_iter):
            num = om.group(1) or om.group(2)
            try:
                n = int(num)
            except (TypeError, ValueError):
                continue
            if not 1 <= n <= 4:
                continue
            end_o = opt_iter[i + 1].start() if i + 1 < len(opt_iter) else len(body)
            text = body[om.end() : end_o].strip()
            text = re.sub(r"\s+", " ", text)
            options.setdefault(str(n), text)

        complete = (
            len(options) == 4
            and all(options.get(str(n), "").strip() for n in (1, 2, 3, 4))
            and len(question_text) > 20
        )
        parsed.append(
            {
                "year": year,
                "subject": subj,
                "qnum": int(qnum),
                "question": question_text,
                "options": options,
                "incomplete": not complete,
                "correctAnswer": None,
            }
        )

    best: dict[tuple[int, str], dict] = {}
    for q in parsed:
        key = (q["qnum"], q["subject"])
        cur = best.get(key)
        size = len(q["question"]) + len(json.dumps(q["options"], ensure_ascii=False))
        if cur is None or size > len(cur["question"]) + len(json.dumps(cur["options"], ensure_ascii=False)):
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
    for year in years:
        paper = parse_paper(year)
        out = os.path.join(OUT_DIR, f"neet_{year}.json")
        with open(out, "w", encoding="utf-8") as f:
            json.dump(paper, f, ensure_ascii=False, indent=1)
        print(
            f"{year}: parsed {paper['total_parsed']} questions, "
            f"{paper['complete']} complete -> {out}"
        )


if __name__ == "__main__":
    main()
