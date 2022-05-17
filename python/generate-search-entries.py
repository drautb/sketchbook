#!/usr/bin/env python

import concurrent.futures
import json
import os
import re
import requests
import sys

from pathlib import Path


DIR = "."
if len(sys.argv) > 1:
    DIR = sys.argv[1]


headers = {
  "Content-Type": "application/xml",
  "Accept": "application/json"
}

def convert_to_search_entry(file):
  try:
    entry_file = str(file) + ".json"
    if os.path.exists(entry_file):
      return "Entry already exists: " + entry_file

    with open(file, "r") as xml_file:
      r = requests.post("http://localhost:5000/stuff/es-bulk-entry", data=xml_file.read().encode(encoding='utf-8'), headers=headers)

    if r.ok:
      with open(entry_file, "w") as entry_file_handle:
        entry_file_handle.write(json.dumps(r.json()) + "\n")
      return "Success - " + str(file)
    else:
      return f"Non-200 response ({r.status_code}) - {file}"


  except Exception as e:
    print("Error occurred: ", e)
    return "Failed: " + str(file)


files = Path(DIR).glob("**/*.xml")
with concurrent.futures.ThreadPoolExecutor() as executor:
    futures = []
    for f in files:
        futures.append(executor.submit(convert_to_search_entry, file=f))

    for future in concurrent.futures.as_completed(futures):
        print(future.result())

