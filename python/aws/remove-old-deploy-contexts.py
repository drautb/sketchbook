#!/usr/bin/env python3

import sys
import boto3
import multiprocessing

from botocore.errorfactory import ClientError
from threading import Thread


if len(sys.argv) != 2:
    raise ValueError('Please provide the bucket name as an argument to the script!')

bucket_name = sys.argv[1]
s3 = boto3.client('s3')


listing = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=1000)

keys_to_delete = []

while True:
  for obj in listing['Contents']:
    key = obj['Key']
    if "/sysps/" in key and "/deploy/" in key:
      keys_to_delete.append(key)

  if listing['IsTruncated']:
    listing = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=1000, ContinuationToken=listing['NextContinuationToken'])
  else:
    break

print("Found %d keys to delete." % len(keys_to_delete))

def delete_deploy_contexts():
  while len(keys_to_delete) != 0:
    sys.stdout.write(".")
    sys.stdout.flush()

    key = keys_to_delete.pop()
    s3.delete_object(Bucket=bucket_name, Key=key)

# Multithread the deletion
threads = []
for _ in range(multiprocessing.cpu_count() * 4):
  t = Thread(target=delete_deploy_contexts)
  t.start()
  threads.append(t)

for t in threads:
  t.join()
