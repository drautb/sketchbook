#!/usr/bin/env python

import os
import sys
import requests
import json

NINE_FIVE_LIST = sys.argv[1]

APID_ENDPOINT = "http://rms.records.service.prod.us-east-1.prod.fslocal.org/artifact/"
SUBMIT_ENDPOINT = "http://cogsworth.records.service.integ.us-east-1.dev.fslocal.org/actions"

def build_action(nine_five, apid):
    return {
        "@type": "text-recognition",
        "input": apid,
        "s3OutputFile": "data/pipeline/" + nine_five[:9] + "/image-stuff/" + nine_five + ".xml",
        "modelProperties": "default-pt"
    }

def get_apid(nine_five):
    r = requests.get(APID_ENDPOINT + nine_five + "/apid", headers={"FS-User-Agent-Chain": "drautb"})
    r.raise_for_status()
    return r.text

def queue_tr(nine_five, apid):
    print("Queueing text recognition for " + nine_five + " (" + apid + ")")
    action = json.dumps(build_action(nine_five, apid))
    r = requests.post(SUBMIT_ENDPOINT, data=action, headers={"Content-Type": "application/json"})
    r.raise_for_status()

for line in open(NINE_FIVE_LIST, 'r'): 
    nine_five = line.strip()
    apid = get_apid(nine_five)
    queue_tr(nine_five, apid)
