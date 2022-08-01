#!/usr/bin/env python

import os
import sys
import requests
import json

NINE_FIVE = sys.argv[1]

APID_ENDPOINT = "http://rms.records.service.prod.us-east-1.prod.fslocal.org/artifact/"
SUBMIT_ENDPOINT = "http://dexter.records.service.integ.us-east-1.dev.fslocal.org/actions"

def build_action(nine_five, apid+):
    return {
        "@type": "FieldStuffToGedcomxAction",
        "s3InputFile": "data/pipeline/" + nine_five[:9] + "/image-stuff/" + nine_five + ".xml",
        "s3OutputFile": "data/pipeline/" + nine_five[:9] + "/records/" + nine_five + ".xml"
    }

def queue_ff_to_gx(nine_five, apid):
    print("Queueing fields to gx conversion for " + nine_five)
    action = json.dumps(build_action(nine_five, apid))
    r = requests.post(SUBMIT_ENDPOINT,
        data=action,
        headers={"Content-Type": "application/json"},
        params={"priority": "true"})
    r.raise_for_status()

apid = get_apid(NINE_FIVE)
queue_ff_to_gx(NINE_FIVE, apid)
