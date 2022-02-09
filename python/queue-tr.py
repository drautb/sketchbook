#!/usr/bin/env python

import os
import sys
import requests
import json
import concurrent.futures

NINE_FIVE_LIST = sys.argv[1]
PROPERTIES = sys.argv[2]

APID_ENDPOINT = "http://rms.records.service.prod.us-east-1.prod.fslocal.org/artifact/"
SUBMIT_ENDPOINT = "http://cogsworth.records.service.integ.us-east-1.dev.fslocal.org/actions"

def build_action(nine_five, apid):
    return {
        "@type": "RecognizeAction",
        "input": apid,
        "s3OutputFile": "data/pipeline/" + nine_five[:9] + "/image-stuff/" + nine_five + ".xml",
        "modelProperties": PROPERTIES
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

def increment_nine_five(nine_five):
    [group, image] = nine_five.split("_")
    next_image = int(image) + 1
    return "%s_%05d" % (group, next_image)

def queue_tr_for_nine_five(nine_five):
    try: 
        nine_five = nine_five.strip()
        apid = get_apid(nine_five)
        queue_tr(nine_five, apid)

        # Queue TR for the next image too, so that the stuff viewer works.
        next_nine_five = increment_nine_five(nine_five)
        apid = get_apid(next_nine_five)
        queue_tr(next_nine_five, apid)

        return "Finished " + nine_five + " and " + next_nine_five
    except Exception as e:
        print("Error occurred: ", e)
        return "Failed: " + nine_five


with concurrent.futures.ThreadPoolExecutor() as executor:
    futures = []
    for line in open(NINE_FIVE_LIST, 'r'): 
        futures.append(executor.submit(queue_tr_for_nine_five, nine_five=line))
    
    for future in concurrent.futures.as_completed(futures):
        print(future.result())

