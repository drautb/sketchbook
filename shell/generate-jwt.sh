#!/usr/bin/env bash

SECRET=$(aws ssm get-parameter --name /priv-1/paas-cfg-binding-sets/caller-secret --with-decryption | jq -r '.Parameter.Value')

HEADER=$(echo '{"typ":"JWT","alg":"none"}' | base64)
PAYLOAD=$(echo "{\"secret\":\"$SECRET\"}" | base64)

printf "%s.%s." "$HEADER" "$PAYLOAD"
