#!/usr/bin/env python3

import argparse
import boto3
import os

from botocore.exceptions import ClientError


parser = argparse.ArgumentParser(description='Remove an SG from all ingress rules in other SGs')
parser.add_argument('security_group_id', help='The id of the EC2 security group to remove')
parser.add_argument('--region', default="us-east-1", help='The region in which to act')
parser.add_argument('--proto', default='tcp', help='The protocol of the ingress rule to remove')
parser.add_argument('--port', default=1836, help='The port of the ingress rule to remove')
parser.add_argument('--dry-run', default=True,
                    help='Print actions that would be taken without actually modifying any security groups')

args = parser.parse_args()
os.environ['AWS_DEFAULT_REGION'] = args.region


# Prelude
target_sg_id = args.security_group_id
print("Deleting all ingress rules from SG: {}".format(target_sg_id))


# Get all SGs that have inbound rules from the target.
ec2_client = boto3.client('ec2')
result = ec2_client.describe_security_groups(Filters=[
    {
      'Name': 'ip-permission.group-id',
      'Values': [
        target_sg_id
      ]
    }
  ])

sgs = result['SecurityGroups']
print("Found {} security groups with inbound rules from {}".format(len(sgs), target_sg_id))


ec2_resource = boto3.resource('ec2')
for sg in sgs:
  sg_id = sg['GroupId']
  if args.dry_run:
    print("[DRY RUN] Removing ingress rule from SG: {}".format(sg_id))
  else:
    print("Removing ingress rule from SG: {}".format(sg_id))

  sg_resource = ec2_resource.SecurityGroup(sg_id)
  try:
    sg_resource.revoke_ingress(
      DryRun = args.dry_run,
      IpPermissions = [
        {
          'UserIdGroupPairs': [
            {
              'GroupId': target_sg_id
            }
          ],
          'IpProtocol': args.proto,
          'FromPort': args.port,
          'ToPort': args.port
        }
      ])

  except ClientError as e:
    if e.response['Error'].get('Code') == 'DryRunOperation':
        continue
    else:
        raise e
