#!/usr/bin/env bash

set -e

creds=$(aws sts assume-role --role-arn $1 --role-session-name $2 --duration 3600)

access_key=$(echo "$creds" | jq -r .Credentials.AccessKeyId)
secret_key=$(echo "$creds" | jq -r .Credentials.SecretAccessKey)
token=$(echo "$creds" | jq -r .Credentials.SessionToken)

cat << EOF > assumed-role-env
export AWS_ACCESS_KEY_ID='$access_key'
export AWS_SECRET_ACCESS_KEY='$secret_key'
export AWS_SESSION_TOKEN='$token'
EOF
