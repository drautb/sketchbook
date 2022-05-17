#!/usr/bin/env python

import json
import re
import sys

from pathlib import Path

DIR = "."
if len(sys.argv) > 1:
    DIR = sys.argv[1]

files = Path(DIR).glob("**/*.json")
for f in files:
    m = re.search(".*((\d{9})_\d{5}).*", str(f))
    dgs95 = m.group(1)
    nine =  m.group(2)

    with open(f"{nine}.json", "a") as bulk_file:
        action = {
            "index": {
                "_index": "transcripts",
                "_id": dgs95
            }
        }
        bulk_file.write(json.dumps(action))
        bulk_file.write("\n")
        with open(f, "r") as entry:
            bulk_file.write(entry.read())

