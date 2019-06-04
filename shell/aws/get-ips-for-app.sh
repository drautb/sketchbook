#!/usr/bin/env bash

set -e

APPLICATION_NAME=$1

ENV_NAMES=($(aws elasticbeanstalk describe-environments --application-name "$APPLICATION_NAME" | jq -j '"\(.Environments[].EnvironmentName) "'))

for env in "${ENV_NAMES[@]}"; do
  aws ec2 describe-instances --filters "Name=tag:Name,Values=$env" | jq -r '.Reservations[].Instances[].PrivateIpAddress'
done