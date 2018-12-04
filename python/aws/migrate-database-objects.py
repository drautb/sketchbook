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

    if key.startswith("rds_postgres/"):
        new_key = key.replace("rds_postgres/", "rds-postgres/")
    elif key.startswith("rds_mysql_v1_0/"):
        new_key = key.replace("rds_mysql_v1_0/", "rds-mysql/")
    elif key.startswith("RDS Aurora Postgres v1_0/"):
        new_key = key.replace("RDS Aurora Postgres v1_0/", "rds-aurora-postgres/")
    else:
        continue

    new_key = new_key.replace("/properties.yml", "/db.yml")

    try:
        s3.head_object(Bucket=bucket_name, Key=new_key)
        raise ValueError("KEY ALREADY EXISTS: " + new_key)
    except ClientError:
        # Not found
        pass

    print(key + "  ==>  " + new_key)
    copy_result = s3.copy_object(
        CopySource={
            'Bucket': bucket_name,
            'Key': key
        },
        CopySourceIfMatch=obj['ETag'],
        Bucket=bucket_name,
        Key=new_key,
        MetadataDirective='COPY',
        TaggingDirective='COPY')

    if copy_result['CopyObjectResult']['ETag'] == obj['ETag']:
        print("Deleting old key: " + key)
        s3.delete_object(Bucket=bucket_name, Key=key)
    else:
        raise ValueError("COPY FAILED! " + str(copy_result))
