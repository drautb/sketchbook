#!/usr/bin/env python

import os
import sys
import requests

PATH_TO_FILES = sys.argv[1]

SUBMIT_ENDPOINT = "http://cogsworth.records.service.integ.us-east-1.dev.fslocal.org/recognition/async"

PARAMS = {
  'modelProperties': 'default-pt'
}

for filename in os.listdir(PATH_TO_FILES):
  if filename.endswith(".jpg"):
    files = {'file': open(os.path.join(PATH_TO_FILES, filename), 'rb')}
    r = requests.post(SUBMIT_ENDPOINT, params=PARAMS, files=files)
    r.raise_for_status()
    guid = r.headers['location'].split("/")[2]
    print(guid)
