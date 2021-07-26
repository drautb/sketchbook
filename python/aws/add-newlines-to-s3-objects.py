#!/usr/bin/env python3

import boto3
import os
import sys
import threading

from botocore.config import Config
from queue import Queue
from threading import Lock


prefix_file = sys.argv[1]
bucket_name = sys.argv[2]

# Increase retries for talking to ec2 metadata (for running in AWS)
os.environ["AWS_METADATA_SERVICE_TIMEOUT"] = "5"
os.environ["AWS_METADATA_SERVICE_NUM_ATTEMPTS"] = "10"

total_keys_processed = 0
sentinel = None
thread_count = os.cpu_count() * 2
prefixes = []
print_and_count_lock = Lock()

session = boto3.Session(profile_name = "FH011_Records_ACE_Operator")
client_config = Config(region_name = "us-east-1")
s3_client = session.client("s3", config = client_config)


def load_prefixes(prefix_file):
  f = open(prefix_file, "r")
  prefixes = f.readlines()
  f.close()
  return prefixes


def add_newline_if_necessary(bucket_name, key):
  if last_byte_is_newline(bucket_name, key):
    return

  add_newline(bucket_name, key)


def add_newline(bucket_name, key):
  response = s3_client.get_object(Bucket=bucket_name, Key=key)
  content = response['Body'].read()
  content += b'\n'
  s3_client.put_object(Bucket=bucket_name, Key=key, Body=content)


def last_byte_is_newline(bucket_name, key):
  last_byte = get_last_byte(bucket_name, key)
  return last_byte == b'\n'


def get_last_byte(bucket_name, key):
  response = s3_client.get_object(Bucket=bucket_name,
                                  Key=key,
                                  Range="bytes=-1")
  return response['Body'].read(1)


def print_dot(thread_processed):
  global print_and_count_lock

  if thread_processed % 5000 == 0:
    with print_and_count_lock:
      print(".", end="", flush=True)


def add_newlines_task(queue, bucket_name):
  global print_and_count_lock
  global total_keys_processed

  thread_processed = 0

  while True:
    p = queue.get()
    if p is sentinel:
      break

    prefix_processed = 0
    response = s3_client.list_objects_v2(Bucket=bucket_name,
                                         Prefix=p,
                                         MaxKeys=1000)
    keys = [o['Key'] for o in response['Contents']]
    for k in keys:
      add_newline_if_necessary(bucket_name, k)
      thread_processed += 1
      prefix_processed += 1
      print_dot(thread_processed)

    while response['IsTruncated']:
      response = s3_client.list_objects_v2(Bucket=bucket_name,
                                           Prefix=p,
                                           MaxKeys=1000,
                                           ContinuationToken=response['NextContinuationToken'])
      keys = [o['Key'] for o in response['Contents']]
      for k in keys:
        add_newline_if_necessary(bucket_name, k)
        thread_processed += 1
        prefix_processed += 1
        print_dot(thread_processed)

    with print_and_count_lock:
      total_keys_processed += prefix_processed

    queue.task_done()

  with print_and_count_lock:
    print("Thread processed %d keys" % thread_processed)


## Main logic
prefixes = load_prefixes(prefix_file)
prefix_queue = Queue()
for p in prefixes:
  p = p.strip()
  prefix_queue.put(p)

threads = [threading.Thread(target = add_newlines_task, args = (prefix_queue, bucket_name)) for n in range(thread_count)]
for t in threads:
  t.start()

prefix_queue.join()
for i in range(thread_count):
  prefix_queue.put(sentinel)

for t in threads:
  t.join()

with print_and_count_lock:
  print("All done. Processed %d keys in %d prefixes" % (total_keys_processed, len(prefixes)))
