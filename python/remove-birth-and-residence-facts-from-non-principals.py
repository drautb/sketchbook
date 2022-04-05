#!/usr/bin/env python3

import glob
import json
import os
import sys

GX_DIRECTORY = sys.argv[1]

for filename in glob.glob(f"{GX_DIRECTORY}/*.json"):
    record = None
    with open(filename, 'r') as f:
        record = json.load(f)

    for p in record["persons"]:
        if p["principal"]:
            continue

        if "facts" in p:
            p["facts"] = [f for f in p["facts"] if not ("Birth" in f["type"] or "Residence" in f["type"])]
            if p["facts"] == []:
                del p["facts"]

    with open(filename, 'w') as f:
        json.dump(record, f, indent=2)

    print(f"Stripped {filename}")

