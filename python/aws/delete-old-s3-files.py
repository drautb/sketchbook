#!/usr/bin/env python3

import sys
import boto3

from botocore.errorfactory import ClientError


if len(sys.argv) != 2:
    raise ValueError('Please provide the bucket name as an argument to the script!')

bucket_name = sys.argv[1]
s3 = boto3.client('s3')


for obj in s3.list_objects(Bucket=bucket_name, MaxKeys=1000)['Contents']:
    key = obj['Key']
    new_key = obj['Key']
    if not key.endswith("/properties.yml"):
        continue

    print("Deleting key: " + key)
    s3.delete_object(Bucket=bucket_name, Key=key)
