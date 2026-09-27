#!/usr/bin/env python3
"""Bulk download NEET previous year question papers (2006-2025)."""
import os
import re
import sys
import time
import urllib.request
import urllib.error

OUTPUT_DIR = os.path.join("assets", "pyq", "downloaded")
SOURCES = [
    ("NEET 2025", "https://medicine.careers360.com/articles/neet-2025-question-paper"),
    ("NEET 2024", "https://medicine.careers360.com/articles/neet-2024-question-paper"),
    (
        "NEET 2023",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/NEET+UG+2023+Question+Paper+(1).pdf",
    ),
    (
        "NEET 2022",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/NEET+UG+2022+Question+Paper+(2).pdf",
    ),
    (
        "NEET 2021",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/NEET+UG+2021+Question+Paper.pdf",
    ),
    (
        "NEET 2020",
        "https://cdnbbsr.s3waas.gov.in/s37bc1ec1d9c3426357e69acd5bf320061/uploads/2022/02/2022021555.pdf",
    ),
    (
        "NEET 2019",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/NEET+2019+Question+Paper.pdf",
    ),
    (
        "NEET 2018",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/NEET+2018+Question+Paper+Code+AA.pdf",
    ),
    (
        "NEET 2017",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/NEET+2017+Question+Paper+Code+A.pdf",
    ),
    (
        "NEET 2016",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/NEET+2016+Question+Paper.pdf",
    ),
    (
        "NEET 2015",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/NEET+2015+Exam+Paper.pdf",
    ),
    (
        "AIPMT 2014",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/AIPMT+2014.pdf",
    ),
    (
        "AIPMT 2013",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/AIPMT+2013.pdf",
    ),
    (
        "AIPMT 2012",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/AIPMT+2012.pdf",
    ),
    (
        "AIPMT 2011",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/AIPMT+2011.pdf",
    ),
    (
        "AIPMT 2010",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/AIPMT+2010.pdf",
    ),
    (
        "AIPMT 2009",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/AIPMT+2009.pdf",
    ),
    (
        "AIPMT 2008",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/AIPMT+2008.pdf",
    ),
    (
        "AIPMT 2007",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/AIPMT+2007.pdf",
    ),
    (
        "AIPMT 2006",
        "https://educart-books.s3.ap-south-1.amazonaws.com/HT+Content+for+Upload/PYP/NEET/AIPMT+2006.pdf",
    ),
]


def safe_filename(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_\-]", "_", name).strip("_") + ".pdf"


def download(name: str, url: str, dest_dir: str) -> bool:
    os.makedirs(dest_dir, exist_ok=True)
    path = os.path.join(dest_dir, safe_filename(name))
    if os.path.exists(path):
        print(f"SKIP {name}: already exists")
        return True

    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0 (NEET Mitos research script)",
            "Accept": "application/pdf,*/*",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
    except urllib.error.HTTPError as e:
        print(f"FAIL {name}: HTTP {e.code}")
        return False
    except Exception as e:
        print(f"FAIL {name}: {type(e).__name__}: {e}")
        return False

    if len(data) < 2000 or data[:4] != b"%PDF":
        print(f"FAIL {name}: unexpected content ({len(data)} bytes, header={data[:4]!r})")
        return False

    with open(path, "wb") as f:
        f.write(data)
    print(f"OK   {name}: {len(data)//1024} KB -> {path}")
    return True


def main() -> int:
    dest = OUTPUT_DIR
    ok = 0
    fail = 0
    for name, url in SOURCES:
        if download(name, url, dest):
            ok += 1
        else:
            fail += 1
        time.sleep(0.5)
    print(f"\nDone. ok={ok} fail={fail}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
