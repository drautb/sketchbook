#!/usr/bin/env bash

CONTENT_TYPE="Content-Type: $DS_CONTENT_TYPE"
AUTH_HEADER="Authorization: Bearer $FSSESSIONID"

response=$(curl -s -H "$CONTENT_TYPE" -H "$AUTH_HEADER" $DS_HOST/ds/services\?type\=$1 | jq -r '.services | @tsv')
ids=( $response )

for id in "${ids[@]}"; do
  body=$(curl -s -H "$CONTENT_TYPE" -H "$AUTH_HEADER" $DS_HOST$id)

  loc=$(echo "$body" | jq -r '.location')
  bp=$(echo "$body" | jq -r '.blueprint')
  sys=$(echo "$body" | jq -r '.system')
  srv=$(echo "$body" | jq -r '.service')
  echo "$loc | $bp | $sys | $srv"
done
