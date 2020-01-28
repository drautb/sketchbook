#!/usr/bin/env python3

import boto3
import sys
import os
import requests
import glob
import yaml

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

# Load GitHub blueprint/systems/services
print("Loading current blueprints in GitHub...", end="")
BLUEPRINTS = {}
FILES = glob.glob("../../ruby/github/blueprint-scraper/fs-eng/*.yml")
FILES.extend(glob.glob("../../ruby/github/blueprint-scraper/fs-webdev/*.yml"))
for blueprint_filename in FILES:
  print(".", end="", flush=True)
  blueprint = {}

  try:
    with open(blueprint_filename) as file:
      blueprint = yaml.full_load(file)

    if 'version' in blueprint and blueprint['version'] == 0.3:
      continue

    blueprint_name = blueprint['name']
    if 'deploy' not in blueprint:
      continue

    if blueprint_name not in BLUEPRINTS:
      BLUEPRINTS[blueprint_name] = {}
      BLUEPRINTS[blueprint_name]['files'] = [blueprint_filename]
    # else:
    #   print("Blueprint already exists in map! blueprint={} blueprint_filename={} previous_files={}".format(blueprint_name, blueprint_filename, BLUEPRINTS[blueprint_name]['files']))

    systems = blueprint['deploy']
    for system_name, services in systems.items():
      if system_name not in BLUEPRINTS[blueprint_name]:
        BLUEPRINTS[blueprint_name][system_name] = {}
      # else:
      #   print("Blueprint system already exists in map! blueprint={} system={}".format(blueprint_name, system_name))

      for service_name, service_def in services.items():
        if service_name not in BLUEPRINTS[blueprint_name][system_name]:
          BLUEPRINTS[blueprint_name][system_name][service_name] = False
        # else:
        #   print("Blueprint service already exists in map! blueprint={} system={} service={}".format(blueprint_name, system_name, service_name))

        if 'binding_sets' in service_def:
          BLUEPRINTS[blueprint_name][system_name][service_name] = True

  except:
    continue


# Load binding sets data
print("\nLoading current binding sets data from S3...", end="")
response = s3.list_objects_v2(Bucket=BUCKET, Prefix=PREFIX)
objects = response['Contents']

s3_service_count = 0
found = 0
missing = 0
other = 0

missing_no_blueprint = 0
missing_with_blueprint = 0

missing_blueprint_keys = []
missing_with_blueprint_keys = []

for obj in objects:
  key = obj['Key'].replace(PREFIX, '')
  if not key:
    continue

  s3_service_count += 1

  blueprint, system, service = key.split('/')
  # print("Checking {} {} {}".format(blueprint, system, service))
  print(".", end="", flush=True)

  r = requests.get(HOST + '/ds/services?blueprint={}&system={}&service={}'.format(blueprint, system, service),
    headers={"Authorization": "Bearer " + SESSIONID})

  if r.status_code == 200:
    found += 1
    continue
  elif r.status_code == 404:
    missing += 1
    # print("MISSING DSS: {}/{}/{}".format(blueprint, system, service))

    if blueprint not in BLUEPRINTS or system not in BLUEPRINTS[blueprint] or service not in BLUEPRINTS[blueprint][system] or not BLUEPRINTS[blueprint][system][service]:
      missing_no_blueprint += 1
      missing_blueprint_keys.append("{}/{}/{}".format(blueprint, system, service))
    else:
      missing_with_blueprint += 1
      missing_with_blueprint_keys.append("{}/{}/{}".format(blueprint, system, service))

  else:
    other += 1
    print("Unrecognized status code for {}/{}/{} - {}".format(blueprint, system, service, r))

summary_template = "\nFOUND: {}\n" +\
  "MISSING FROM DSS: {}\n" +\
  "MISSING BLUEPRINT: {} (Ratio: {}%)\n" +\
  "MISSING DSS WITH BLUEPRINT: {} (Ratio: {}%)\n" +\
  "UNKNOWN DSS RESPONSE: {}"
print(summary_template.format(found,
  missing,
  missing_no_blueprint, int((missing_no_blueprint / missing) * 100.0),
  missing_with_blueprint, int((missing_with_blueprint / missing) * 100.0),
  other))

print("--------------------------------------------------")
print("| B/S/S Present in GitHub                        |")
print("--------------------------------------------------")
for k in missing_with_blueprint_keys:
  print("| {}".format(k))
print("--------------------------------------------------")