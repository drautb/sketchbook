#!/usr/bin/env python3

import sys
import boto3
import json

acct_mapping = {
  '633002655422': 'fh2',
  '074150922133': 'fh5',
  '643055571372': 'fh3',
  '914248642252': 'fh1',
  '221453998677': 'fh7',
  '987239284182': 'DPTDEV!'
}

with open('rds-instances.json', 'r') as f:
  events = json.load(f)

missing_tags = []

for e in events:
  r = e['result']
  rds_id = r['id']
  acct = r['account_id']
  region = r['region']

  arn = "arn:aws:rds:{}:{}:db:{}".format(region, acct, rds_id)
  print("Checking Tags For: " + arn)

  profile_name = "{}-{}".format(acct_mapping[acct], region)
  session = boto3.Session(profile_name=profile_name)
  rds = session.client('rds')

  result = rds.list_tags_for_resource(ResourceName=arn)

  blueprint = ''
  council = ''
  deploy_meta = ''
  for t in result['TagList']:
    if t['Key'] == 'council':
      council = t['Value']
    elif t['Key'] == 'blueprint':
      blueprint = t['Value']
    elif t['Key'] == 'deploy-meta':
      deploy_meta = t['Value']

  if blueprint == '' or council == '':
    missing_tags.append({
      'arn': arn,
      'blueprint': blueprint,
      'council': council,
      'deployMeta': deploy_meta
    })

with open('rds-results.json', 'w') as f:
  f.write(json.dumps(missing_tags))
