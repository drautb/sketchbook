#!/usr/bin/env python3

import boto3
import os
import sys
import threading

from botocore.config import Config
from queue import Queue
from threading import Lock


bucket_name = sys.argv[1]


def list_prefixes(bucket_name, prefix):
  common_prefixes = []
  response = s3_client.list_objects_v2(Bucket = bucket_name,
                                       Delimiter = "/",
                                       MaxKeys = 1000,
                                       Prefix = prefix)

  if 'CommonPrefixes' not in response:
    return common_prefixes

  common_prefixes = [p['Prefix'] for p in response['CommonPrefixes']]

  while response['IsTruncated']:
    response = s3_client.list_objects_v2(Bucket=bucket_name,
                                         Delimiter="/",
                                         MaxKeys=1000,
                                         Prefix=prefix,
                                         ContinuationToken=response['NextContinuationToken'])
    if 'CommonPrefixes' not in response:
      return common_prefixes

    common_prefixes += [p['Prefix'] for p in response['CommonPrefixes']]

  return common_prefixes


def process_prefix_task(queue, bucket_name):
  while True:
    p = queue.get()
    if p is sentinel:
      break

    prefixes = list_prefixes(bucket_name, p)
    if prefixes:
      for p in prefixes:
        if "/dgs=" in p:
          with print_lock:
            print(p)
        else:
          queue.put(p)
    else:
      with print_lock:
        print(p)

    queue.task_done()


print_lock = Lock()
queue = Queue()
sentinel = None
thread_count = os.cpu_count()

session = boto3.Session(profile_name = "FH011_Records_ACE_Operator")
client_config = Config(region_name = "us-east-1")
s3_client = session.client("s3", config = client_config)


queue.put("image-stuff/")
queue.put("record-stuff/")
queue.put("records/")

threads = [threading.Thread(target = process_prefix_task, args = (queue, bucket_name)) for n in range(thread_count)]
for t in threads:
  t.start()

queue.join()
for i in range(thread_count):
  queue.put(sentinel)

for t in threads:
  t.join()
