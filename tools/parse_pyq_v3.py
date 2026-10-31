"""Parse NEET PYQ layout text into structured MCQs (v3 - approach used).

Every page is parsed with BOTH column-restoration strategies
  A) split each line at its widest internal space-run
  B) detect the page's modal seam column first, then classify lines
and the per-page variant that yields more *complete* questions is kept.
Content-year selection: 2019's PDF is a solutions book (text starts with
"Option (a) is correct."), so it is excluded from question extraction.

Answers: no answer-key source exists in-repo; correctAnswer stays null.
Enrichment with an official key PDF is a follow-up (drop key PDFs into
NEET_PYQ/ and extend tools/enrich_with_keys.py).
"""
import json
import os
import re
import sys
from collections import Counter
from parse_pyq_v2 import de_column_page as de_column_seam
from parse_pyq import de_column  # widest-gap strategy (v1)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEXT_DIR = os.path.join(ROOT, "outputs", "pyq_text")
OUT_DIR = os.path.join(ROOT, "outputs", "pyq_parsed")

QNUM_RE = re.compile(r"(?m)^\s*(\d{1,3})\s*\.\s+")
OPT_RE = re.compile(r"(?:\((\d)\)\s*|\s(\d)\)\s+)")
STRAY_TOKENS = re.compile(r"(?m)(R6)\s*$")

YEARS = [2015, 2016, 2017, 2018, 2021, 2022]  # 2019 = solutions book


def extract_questions(linear: str):
    """Shared question/option segmentation over de-columned page text."""
    sections: list[tuple[str, int]] = []
    for m in re.finditer(r"(?i)Section\s*-?\s*[AB]?\s*\(([^)]{0,30})\)", linear):
        raw_name = re.sub(r"[\s:()]+", "", m.group(1))
        name = {
            "BiologyBotany": "Botany",
            "Biology:Botany": "Botany",
            "BiologyZoology": "Zoology",
            "Biology:Zoology": "Zoology",
        }.get(raw_name)
        if name is None:
            name = raw_name.title() if raw_name else "Unknown"
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
        question_text = re.sub(r"^\d{1,3}\.\s*", "", question_text)

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
                "year": None,  # set by caller
                "subject": subj,
                "qnum": int(qnum),
                "question": question_text,
                "options": options,
                "incomplete": not complete,
                "correctAnswer": None,
            }
        )
    return parsed


def rank(parsed) -> int:
    """Quality score: complete questions, punishing cross-contamination."""
    return sum(0 if q["incomplete"] else 1 for q in parsed)


def parse_paper(year: int) -> dict:
    raw = open(os.path.join(TEXT_DIR, f"neet_{year}.txt"), encoding="utf-8").read()
    pages = raw.split("===== PAGE BREAK =====")

    page_questions = []
    for page in pages:
        got = {}
        for strategy, fn in (("gap", de_column), ("seam", de_column_seam)):
            parsed = extract_questions(fn(page))
            for q in parsed:
                q["year"] = year
            got[strategy] = (parsed, rank(parsed))
        # Choose per page; tie -> 'gap' (v1 was historically stabler).
        (parsed, _) = max(
            got.items(), key=lambda kv: (kv[1][1], kv[0] == "gap")
        )[1] if False else max(got.values(), key=lambda t: t[1])
        page_questions.append(parsed)

    flat = [q for qlist in page_questions for q in qlist]
    best: dict[tuple[int, str], dict] = {}
    for q in flat:
        key = (q["qnum"], q["subject"])
        cur = best.get(key)
        size = len(q["question"]) + len(json.dumps(q["options"], ensure_ascii=False))
        if cur is None or size > len(cur["question"]) + len(json.dumps(cur["options"], ensure_ascii=False)):
            best[key] = q

    final = sorted(best.values(), key=lambda q: (q["subject"], q["qnum"]))

    # Subject fallback by question number: NEET papers number questions
    # continuously per subject block - Physics 1-45/50, Chemistry next etc.
    blocks_180 = [(1, 45, "Physics"), (46, 90, "Chemistry"), (91, 135, "Botany"), (136, 180, "Zoology")]
    blocks_200 = [(1, 50, "Physics"), (51, 100, "Chemistry"), (101, 150, "Botany"), (151, 200, "Zoology")]
    blocks = blocks_200 if max(best, default=(0,))[0] > 150 or len(final) > 185 else blocks_180
    for q in final:
        if q["subject"] == "Unknown":
            for lo, hi, name in blocks:
                if lo <= q["qnum"] <= hi:
                    q["subject"] = name
                    break
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
    years = [int(a) for a in sys.argv[1:]] or YEARS
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
