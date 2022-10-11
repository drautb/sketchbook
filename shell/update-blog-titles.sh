#!/usr/bin/env bash

set -e

for f in $(find -E . -type f -regex "\./[0-9]+.pdf"); do 
  ID="$(basename "$f" .pdf)"
  echo "Getting title for $ID..."

  METADATA=$(curl -sLG -H "Authorization: Bearer $CONFLUENCE_TOKEN" "https://$CONFLUENCE_HOST/rest/api/content/$ID")
  TITLE=$(echo "$METADATA" | jq -r '.title')
  CREATED=$(echo "$METADATA" | jq -r '.history.createdDate | .[0:10]')

  TMP="$(mktemp)"
  mv "$f" "$TMP"
  mv "$TMP" "$CREATED-$TITLE.pdf"
done

