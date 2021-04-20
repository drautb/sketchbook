#!/usr/bin/env python

import os
import sys
import requests
import json

GUID_LIST = sys.argv[1]

DOWNLOAD_ENDPOINT = "http://cogsworth.records.service.integ.us-east-1.dev.fslocal.org/transcriptions"

for guid in open(GUID_LIST, 'r').read().splitlines():
  print(guid)
  r = requests.get(DOWNLOAD_ENDPOINT + "/" + guid)
  r.raise_for_status()
  with open(guid + '.json', 'w') as outfile:
    json.dump(r.json(), outfile)
