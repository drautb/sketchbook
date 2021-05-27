#!/usr/bin/env python

import os
import sys
import requests
import json

NINE_FIVE_LIST = sys.argv[1]

DOWNLOAD_ENDPOINT = "http://dexter.records.service.integ.us-east-1.dev.fslocal.org/image/"

for nine_five in open(NINE_FIVE_LIST, 'r').read().splitlines():
    print("Downloading image stuff for " + nine_five + "...")
    r = requests.get(DOWNLOAD_ENDPOINT + "/" + nine_five + "/image-stuff")
    r.raise_for_status()
    with open(nine_five + '.json', 'w') as outfile:
        json.dump(r.json(), outfile)
