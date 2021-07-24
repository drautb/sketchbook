#!/usr/bin/env python3

import boto3
import concurrent.futures
import os
import sys

from botocore.config import Config


prefix_file = sys.argv[1]
bucket_name = sys.argv[2]

# Increase retries for talking to ec2 metadata (for running in AWS)
os.environ["AWS_METADATA_SERVICE_TIMEOUT"] = "5.0"
os.environ["AWS_METADATA_SERVICE_NUM_ATTEMPTS"] = "10"

total_keys_processed = 0
prefixes = []

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


def farm_out_keys(executor, bucket_name, keys):
  global total_keys_processed
  futures = []
  for key in keys:
    futures.append(executor.submit(add_newline_if_necessary, bucket_name=bucket_name, key=key))

  for future in concurrent.futures.as_completed(futures):
    total_keys_processed += 1

  print(".", end="")


def add_newlines_to_all_files(prefix_file, bucket_name):
  global prefixes
  prefixes = load_prefixes(prefix_file)

  with concurrent.futures.ThreadPoolExecutor() as executor:
    for p in prefixes:
      p = p.strip()
      prefix_key_count = 0
      response = s3_client.list_objects_v2(Bucket=bucket_name,
                                           Prefix=p,
                                           MaxKeys=1000)
      keys = [o['Key'] for o in response['Contents']]
      farm_out_keys(executor, bucket_name, keys)
      prefix_key_count += len(keys)

      while response['IsTruncated']:
        response = s3_client.list_objects_v2(Bucket=bucket_name,
                                             Prefix=p,
                                             MaxKeys=1000,
                                             ContinuationToken=response['NextContinuationToken'])
        keys = [o['Key'] for o in response['Contents']]
        farm_out_keys(executor, bucket_name, keys)
        prefix_key_count += len(keys)

      print("\nProcessed %d keys in prefix. (%d total so far)" % (prefix_key_count, total_keys_processed))


add_newlines_to_all_files(prefix_file, bucket_name)

print("All done. Processed %d keys in %d prefixes" % (total_keys_processed, len(prefixes)))
