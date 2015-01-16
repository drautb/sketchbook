#!/usr/bin/env sh

# The purpose of this script is to cleanup resources in AWS leftover
# from acceptance tests. It invokes a number of other scripts in
# a particular order to accomplish this.

set -x

RDS_CLEANUP_SCRIPT="python ../../python/aws/delete-acceptance-test-rds-snapshots.py"
IAM_CLEANUP_SCRIPT="ruby ../../ruby/aws/remove-iam-users-from-service-groups.rb"
CFN_CLEANUP_SCRIPT="ruby ../../ruby/aws/delete-old-cloudformation-stacks.rb"
EB_CLEANUP_SCRIPT="python ../../python/aws/delete-empty-beanstalk-applications.py"

STEP_COUNT="4"

echo "*** STEP 1/$STEP_COUNT: DELETING OLD RDS SNAPSHOTS ***"
$RDS_CLEANUP_SCRIPT

echo "*** STEP 2/$STEP_COUNT: REMOVING OLD IAM USERS ***"
$IAM_CLEANUP_SCRIPT

echo "*** STEP 3/$STEP_COUNT: DELETING OLD CFN STACKS ***"
$CFN_CLEANUP_SCRIPT

echo "*** STEP 4/$STEP_COUNT: DELETEING EMPTY BEANSTALK APPLCIATIONS ***"
$EB_CLEANUP_SCRIPT


