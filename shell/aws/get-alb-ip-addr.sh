#!/usr/bin/env bash
#
# Lookup private IPs for ALBs in AWS.
# https://aws.amazon.com/premiumsupport/knowledge-center/elb-find-load-balancer-IP/

ALB_NAME=$1

ARN=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" | jq -r '.LoadBalancers[].LoadBalancerArn')
ALB_ID=$(basename "$ARN")

aws ec2 describe-network-interfaces --filters Name=description,Values="ELB app/$ALB_NAME/$ALB_ID" --query 'NetworkInterfaces[*].PrivateIpAddresses[*].PrivateIpAddress' --output text
