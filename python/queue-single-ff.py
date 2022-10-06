#!/usr/bin/env python

import os
import sys
import requests
import json

NINE_FIVE = sys.argv[1]
LANG = sys.argv[2]
SESSION_ID = sys.argv[3]

APID_ENDPOINT = "http://rms.records.service.prod.us-east-1.prod.fslocal.org/artifact/"
SUBMIT_ENDPOINT = "http://cogsworth.records.service.prod.us-east-1.prod.fslocal.org/actions"

def build_action(nine_five, apid):
    return {
        "@type": "FindFieldsAction",
        "input": apid,
        "s3OutputFile": "data/pipeline/" + nine_five[:9] + "/image-fields/" + nine_five + ".xml",
        "modelProperties": "default-" + LANG
    }

def get_apid(nine_five):
    r = requests.get(APID_ENDPOINT + nine_five + "/apid", headers={"FS-User-Agent-Chain": "drautb", "Authorization": f"Bearer {SESSION_ID}"})
    r.raise_for_status()
    return r.text

def queue_tr(nine_five, apid):
    print("Queueing field finding for " + nine_five + " (" + apid + ")")
    action = json.dumps(build_action(nine_five, apid))
    r = requests.post(SUBMIT_ENDPOINT,
        data=action,
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {SESSION_ID}"},
        params={"priority": "true"})
    r.raise_for_status()

apid = get_apid(NINE_FIVE)
queue_tr(NINE_FIVE, apid)
