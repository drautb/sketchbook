#!/usr/bin/env python3

import sys
import boto3
import time

if len(sys.argv) != 2:
    raise ValueError('Please provide the domain name as an argument to the script!')

domain_name = sys.argv[1]
es = boto3.client('es')

print("Monitoring domain: {}".format(domain_name))

done = False
while not done:
  response = es.describe_elasticsearch_domain(DomainName=domain_name)
  status = response['DomainStatus']
  processing = status['Processing']

  endpoint = None
  if 'Endpoint' in status:
    endpoint = status['Endpoint']

  endpoints = None
  if 'Endpoints' in status:
    endpoints = status['Endpoints']

  t = time.localtime()
  current_time = time.strftime("%H:%M:%S", t)
  print(current_time)
  print("PROCESSING: {}\nENDPOINT: {}\nENDPOINTS: {}\n".format(processing, endpoint, endpoints), flush=True)
  time.sleep(5)

