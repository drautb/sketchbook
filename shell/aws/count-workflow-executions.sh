#!/usr/bin/env bash

DOMAIN="$1"
PROVISIONER="$2"
VERSION="$3"
TYPE="$4"

PHASES=("check" "preDeploy" "bind" "deploy" "integrate" "unintegrate" "undeploy" "unbind" "postundeploy")
ACCOUNTS=("fh1" "fh3" "fh5" "fh7")

for account in "${ACCOUNTS[@]}"; do
  printf "Counting $TYPE executions in %s:\\n" "$account"
  for phase in "${PHASES[@]}"; do
    count=$(aws swf count-$TYPE-workflow-executions --domain "$DOMAIN" --start-time-filter oldestDate=0,latestDate="$(date +%s)" --type-filter name="$PROVISIONER.$phase",version="$VERSION" --profile="$account-us-east-1" | jq -r '.count')
    echo "$phase: $count"
  done
  printf "\\n"
done

