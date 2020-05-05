#!/usr/bin/env bash

app_name=$1
env_name=$2

aws elasticbeanstalk describe-configuration-settings --application-name "$app_name" --environment-name "$env_name" | jq -r '.ConfigurationSettings[].OptionSettings[] | select(.Namespace == "aws:elasticbeanstalk:application:environment") | [.OptionName, .Value] | @csv'
