#!/usr/bin/env python3

import sys
import boto3

from botocore.errorfactory import ClientError


if len(sys.argv) != 3:
    raise ValueError('Please provide the old and new bucket names as arguments to the script!')

old_bucket_name = sys.argv[1]
new_bucket_name = sys.argv[2]
s3 = boto3.client('s3')


listing = s3.list_objects_v2(Bucket=old_bucket_name, MaxKeys=1000)

while True:
  for obj in listing['Contents']:
    key = obj['Key']
    if "/sysps/service-context/" in key:
      try:
        s3.head_object(Bucket=new_bucket_name, Key=key)

        print("Deleting key: " + key)
        s3.delete_object(Bucket=old_bucket_name, Key=key)
      except ClientError as e:
        None # Doesn't exist in new bucket, so leave the key here.

  if listing['IsTruncated']:
    listing = s3.list_objects_v2(Bucket=old_bucket_name, MaxKeys=1000, ContinuationToken=listing['NextContinuationToken'])
  else:
    break
