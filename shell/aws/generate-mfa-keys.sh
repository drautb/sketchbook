#!/usr/bin/env bash

set -e

creds=$(aws sts get-session-token --serial-number arn:aws:iam::$AWS_ACCOUNT_ID:mfa/$AWS_USERNAME --token-code "$1")

access_key=$(echo "$creds" | jq -r .Credentials.AccessKeyId)
secret_key=$(echo "$creds" | jq -r .Credentials.SecretAccessKey)
token=$(echo "$creds" | jq -r .Credentials.SessionToken)

cat << EOF > ~/dpt-development-mfa-env
export AWS_ACCESS_KEY_ID='$access_key'
export AWS_SECRET_ACCESS_KEY='$secret_key'
export AWS_SESSION_TOKEN='$token'
EOF
