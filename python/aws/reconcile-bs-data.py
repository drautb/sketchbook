#!/usr/bin/env python3

import boto3
import sys
import os
import requests

s3 = boto3.client('s3')
sts = boto3.client('sts')

HOST = os.environ['DSS_HOST']
SESSIONID = os.environ['FSSESSIONID']

if len(sys.argv) != 2:
  raise ValueError('Please provide the system name as an argument to the script!')

SYSTEM = sys.argv[1]

ACCOUNT_ID = sts.get_caller_identity()['Account']
BUCKET = "paas-services-us-east-1-" + ACCOUNT_ID
PREFIX = "s3/paas-sps-binding-sets-" + SYSTEM + "-s3/"

response = s3.list_objects_v2(Bucket=BUCKET, Prefix=PREFIX)
objects = response['Contents']

s3_service_count = 0
found = 0
missing = 0
other = 0
for obj in objects:
  key = obj['Key'].replace(PREFIX, '')
  if not key:
    continue

  s3_service_count += 1

  blueprint, system, service = key.split('/')
  # print("Checking {} {} {}".format(blueprint, system, service))

  r = requests.get(HOST + '/ds/services?blueprint={}&system={}&service={}'.format(blueprint, system, service),
    headers={"Authorization": "Bearer " + SESSIONID})

  if r.status_code == 200:
    found += 1
    continue
  elif r.status_code == 404:
    missing += 1
    # print("MISSING DSS: {}/{}/{}".format(blueprint, system, service))
  else:
    other += 1
    print("Unrecognized status code for {}/{}/{} - {}".format(blueprint, system, service, r))

print("FOUND: {}    MISSING: {}    OTHER: {}".format(found, missing, other))