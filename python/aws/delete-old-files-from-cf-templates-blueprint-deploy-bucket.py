#!/usr/bin/env python3

import sys
import boto3

from botocore.errorfactory import ClientError


if len(sys.argv) != 2:
    raise ValueError('Please provide the bucket name as an argument to the script!')

bucket_name = sys.argv[1]
s3 = boto3.client('s3')


listing = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=1000)

while True:
  for obj in listing['Contents']:
    key = obj['Key']
    if key.endswith("/deployartifact.zip") or \
      "/service_properties/deploy_id/" in key or \
      "us-east-1/dynamodbtable/" in key or \
      "us-east-1/sqs/" in key:

      print("Deleting key: " + key)
      s3.delete_object(Bucket=bucket_name, Key=key)

  if listing['IsTruncated']:
    listing = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=1000, ContinuationToken=listing['NextContinuationToken'])
  else:
    break
