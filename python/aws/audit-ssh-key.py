#!/usr/bin/env python

# audit-ssh-key.py
#
# Given the name of an EC2 SSH Keypair, and a region, this script will determine
# how many EC2 instances are using that keypair, as well as how many associated
# ASGs and Launch Configurations.

import argparse
import boto3
import os

parser = argparse.ArgumentParser(description='Report on AWS SSH key usage')
parser.add_argument('keypair_name', help='The name of the AWS EC2 keypair to audit')
parser.add_argument('--region', dest='region', default="us-east-1", help='The region to audit')
parser.add_argument('--stopped', action='store_true', default=False,
                    help='Include a detailed report for stopped instances. (Id and Tags)')

args = parser.parse_args()

os.environ['AWS_DEFAULT_REGION'] = args.region

REPORT_LENGTH = 72
NUMBER_COLUMN_WIDTH = 4


def fmt_pct(num, denom):
    percent_str = str(int(100 * (num / float(denom)))) + "%"
    return percent_str.rjust(NUMBER_COLUMN_WIDTH)


def fmt_num(num):
    return str(num).rjust(NUMBER_COLUMN_WIDTH)


def fmt_three_cols(num, denom):
    return fmt_num(num) + "  |  " + fmt_num(denom) + "  |  " + fmt_pct(num, denom)


print "Auditing key usage in " + args.region + " for key '" + args.keypair_name + "'..."

ec2_client = boto3.client('ec2')
ec2 = boto3.resource('ec2')
autoscaling_client = boto3.client('autoscaling')

asg_instances_paginator = autoscaling_client.get_paginator('describe_auto_scaling_instances')
lcfg_paginator = autoscaling_client.get_paginator('describe_launch_configurations')


# This blows up if the key doesn't exist
print "Making sure key exists...\n"
response = ec2_client.describe_key_pairs(KeyNames=[args.keypair_name])


# Gather all the instance data.
all_ec2_instances = {}
for i in ec2.instances.all():
    all_ec2_instances[i.instance_id] = i

asg_instances = {}
asg_instance_pages = asg_instances_paginator.paginate()
asg_instance_ids = []
for page in asg_instance_pages:
    for i in page['AutoScalingInstances']:
        # I noticed that sometimes the ASG query includes instances that don't actually exist...
        # This filters those out.
        if i['InstanceId'] in all_ec2_instances:
            asg_instance_ids.append(i['InstanceId'])
            asg_instances[i['InstanceId']] = i

ec2_instances = {}
for i in filter(lambda i: i.instance_id not in asg_instance_ids, all_ec2_instances.values()):
    ec2_instances[i.instance_id] = i

launch_configs = {}
lcfg_pages = lcfg_paginator.paginate()
for p in lcfg_pages:
    for lcfg in p['LaunchConfigurations']:
        launch_configs[lcfg['LaunchConfigurationName']] = lcfg

# Prepare data for the key usage report.
ec2_keys = len(filter(lambda i: i.key_name == args.keypair_name, ec2_instances.values()))

asg_keys = 0
for iid in asg_instances.keys():
    if all_ec2_instances[iid].key_name == args.keypair_name:
        asg_keys += 1

print '=' * REPORT_LENGTH
print "'" + args.keypair_name + "' Key Usage"
print '=' * REPORT_LENGTH
print "EC2 Instances   |  " + fmt_three_cols(ec2_keys, len(ec2_instances))
print "ASG Instances   |  " + fmt_three_cols(asg_keys, len(asg_instances))
print '-' * REPORT_LENGTH
print "Total           |  " + fmt_three_cols(ec2_keys + asg_keys, len(all_ec2_instances))
print '=' * REPORT_LENGTH


# Prepare data for the instance state report
states = {
    'pending': 0,
    'running': 0,
    'shutting-down': 0,
    'terminated': 0,
    'stopping': 0,
    'stopped': 0
}

stopped_instances = []

key_count = 0
for i in all_ec2_instances.values():
    if i.key_name == args.keypair_name:
        key_count += 1
        states[i.state['Name']] += 1
        if i.state['Name'] == 'stopped':
            stopped_instances.append(i)

print "\n"
print '=' * REPORT_LENGTH
print "EC2 Instance State (All Using '" + args.keypair_name + "' Key)"
print '=' * REPORT_LENGTH
count = states['pending']
print "Pending         |  " + fmt_three_cols(count, key_count)
count = states['running']
print "Running         |  " + fmt_three_cols(count, key_count)
count = states['shutting-down']
print "Shutting Down   |  " + fmt_three_cols(count, key_count)
count = states['terminated']
print "Terminated      |  " + fmt_three_cols(count, key_count)
count = states['stopping']
print "Stopping        |  " + fmt_three_cols(count, key_count)
count = states['stopped']
print "Stopped         |  " + fmt_three_cols(count, key_count)

if args.stopped:
    print '=' * REPORT_LENGTH
    print "STOPPED INSTANCE LIST"
    print '-' * REPORT_LENGTH
    for i in stopped_instances:
        tag_str = ""
        max_tag_key_length = max(map(lambda t: len(t['Key']), i.tags)) + 1
        for t in i.tags:
            tag_str += "  " + (t['Key'] + ":").ljust(max_tag_key_length) + " " + t['Value'] + "\n"
        tag_str = "\n".join(sorted(filter(None, tag_str.split("\n"))))
        print i.id + "\n" + tag_str + "\n"

print '=' * REPORT_LENGTH


# Prepare data for the launch config report.
lcfg_keys = len(filter(lambda l: l['KeyName'] == args.keypair_name, launch_configs.values()))

launch_cfg_names = set(launch_configs.keys())
tied_lcfg_names = set()
for i in asg_instances.values():
    try:
        tied_lcfg_names.add(i['LaunchConfigurationName'])
    except KeyError:
        pass  # Some instances can be attached to an ASG without a launch config

for n in tied_lcfg_names:
    launch_cfg_names.remove(n)

orphaned_cfgs = len(launch_cfg_names)

print "\n"
print '=' * REPORT_LENGTH
print "Launch Configurations"
print '=' * REPORT_LENGTH
print "Using Key       |  " + fmt_three_cols(lcfg_keys, len(launch_configs))
print '-' * REPORT_LENGTH
print "Not tied to ASG |  " + fmt_three_cols(orphaned_cfgs, lcfg_keys)
print '-' * REPORT_LENGTH
print "Delta           |  " + fmt_three_cols(lcfg_keys - orphaned_cfgs, lcfg_keys)
print '=' * REPORT_LENGTH
