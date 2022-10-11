#!/usr/bin/env bash

TMP_FILE=$(mktemp)

echo "Downloading post listing..."
curl -sG -H "Authorization: Bearer $CONFLUENCE_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  --data-urlencode "cql=(creator=drautb and type=blogpost)" \
  "https://$CONFLUENCE_HOST/rest/api/content/search?limit=200" > "$TMP_FILE"

for post in $(jq -r '.results[] | @base64' "$TMP_FILE"); do
  _jq() {
    echo "${post}" | base64 --decode | jq -r "${1}"
  }

  ID="$(_jq '.id')"
  TITLE="$(_jq '.title')"
  URL="$(_jq '._links.webui')"
  echo "Downloading: $TITLE..."

  FILENAME="$ID.pdf"
  if [[ "$URL" =~ drautb/([0-9]{4})/([0-9]{2})/([0-9]{2})/ ]]; then 
    FILENAME="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-$TITLE.pdf"
  fi

  curl -sL -H "Authorization: Bearer $CONFLUENCE_TOKEN" \
    --output "$FILENAME" \
    "https://$CONFLUENCE_HOST/spaces/flyingpdf/pdfpageexport.action?pageId=$ID"
done
