#!/usr/bin/env python3

# Simple script to figure out how many SGs we have that aren't being used.
# If it proves fruitful, I might make it more intelligent and see if we can
# safely delete some of them.

import boto3

ec2_client = boto3.client('ec2')
elb_client = boto3.client('elb')
rds_client = boto3.client('rds')

sg_paginator = ec2_client.get_paginator('describe_security_groups')
sg_page_iterator = sg_paginator.paginate()

security_groups = {}
security_group_attachments = {}
for page in sg_page_iterator:
  for sg in page['SecurityGroups']:
    security_groups[sg['GroupId']] = sg
    security_group_attachments[sg['GroupId']] = []

print("Found {:d} security groups.".format(len(security_groups)))

instance_paginator = ec2_client.get_paginator('describe_instances')
instance_page_iterator = instance_paginator.paginate()

instances = {}
for page in instance_page_iterator:
  for res in page['Reservations']:
    for instance in res['Instances']:
      instances[instance['InstanceId']] = instance

print("Found {:d} EC2 instances.".format(len(instances)))

elb_paginator = elb_client.get_paginator('describe_load_balancers')
elb_page_iterator = elb_paginator.paginate()

elbs = {}
for page in elb_page_iterator:
  for elb in page['LoadBalancerDescriptions']:
    elbs[elb['LoadBalancerName']] = elb

print("Found {:d} Load Balancers.".format(len(elbs)))

rds_paginator = rds_client.get_paginator('describe_db_instances')
rds_page_iterator = rds_paginator.paginate()

rds_instances = {}
for page in rds_page_iterator:
  for rds_instance in page['DBInstances']:
    rds_instances[rds_instance['DBInstanceIdentifier']] = rds_instance

print("Found {:d} RDS instances.".format(len(rds_instances)))

# Start figuring out which SGs aren't used by any of these.
for sg_id, sg in security_groups.items():

  # EC2 Instances
  for instance_id, instance in instances.items():
    instance_sgs = instance['SecurityGroups']
    instance_using_sg = False
    for sg in instance_sgs:
      if sg['GroupId'] == sg_id:
        instance_using_sg = True

    if instance_using_sg:
      security_group_attachments[sg_id].append(instance)

  # ELBs
  for elb_name, elb in elbs.items():
    if sg_id in elb['SecurityGroups']:
      security_group_attachments[sg_id].append(elb)

  # RDS Instances
  for db_id, db in rds_instances.items():
    vpc_sgs = db['VpcSecurityGroups']
    in_use = False
    for vpc_sg in vpc_sgs:
      if vpc_sg['VpcSecurityGroupId'] == sg_id:
        in_use = True

    if in_use:
      security_group_attachments[sg_id].append(db)

# Print results
for sg_id, attachments in security_group_attachments.items():
  if not attachments:
    print("SG {} has no attachments! (Name: {})".format(sg_id, security_groups[sg_id]['GroupName']))
