#!/usr/bin/env python

# check-scaling-profile.py
#
# Given the name of a blueprint and blueprint system, this script will print some
# data for each autoscaling group.

import argparse
import boto3
import os

parser = argparse.ArgumentParser(description='Report on AWS scaling activity')
parser.add_argument('--beanstalk-application-name', dest='application_name', help='The beanstalk application name')

args = parser.parse_args()

beanstalk = boto3.client('elasticbeanstalk')
ec2 = boto3.client('ec2')
autoscaling = boto3.client('autoscaling')

# Get the autoscaling group names from Beanstalk
response = beanstalk.describe_environments(ApplicationName=args.application_name, IncludeDeleted=False)
environment_ids = [env['EnvironmentId'] for env in response['Environments']]

autoscaling_groups = []
for env_id in environment_ids:
  response = beanstalk.describe_environment_resources(EnvironmentId=env_id)
  autoscaling_groups = autoscaling_groups + [asg['Name'] for asg in response['EnvironmentResources']['AutoScalingGroups']]

response = autoscaling.describe_auto_scaling_groups(AutoScalingGroupNames=autoscaling_groups)
asg_descriptions = response['AutoScalingGroups']

for asg in asg_descriptions:
  asg_name = asg['AutoScalingGroupName']
  response = ec2.describe_instances(Filters=[
      {
        'Name': 'instance-lifecycle',
        'Values': ['spot']
      },
      {
        'Name': 'tag:aws:autoscaling:groupName',
        'Values': [asg_name]
      }
    ])
  spot_count = 0
  for r in response['Reservations']:
    spot_count += len(filter(lambda i: i['State']['Name'] == 'running', r['Instances']))

  actual = len(filter(lambda i: i['LifecycleState'] == 'InService', asg['Instances']))
  print("ASG: {}\n\tMin: {:<8}\tMax: {:<8}\tDesired: {:<8}\tActual: {:<8}\tSpot: {:<8}\n".format(asg_name, asg['MinSize'], asg['MaxSize'], asg['DesiredCapacity'], actual, spot_count))
