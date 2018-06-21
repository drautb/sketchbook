#!/usr/bin/env bash

result="$(curl -s "http://data.fcc.gov/api/license-view/basicSearch/getLicenses?searchValue=$FRN&format=json" | jq -r '.status')"
echo "Result: $result"
if [ "$result" = "Info" ]; then
  curl -X POST "https://slack.com/api/chat.postMessage?token=$SLACK_TOKEN&channel=$CHANNEL_ID&text=No%20license%20yet.&as_user=false&pretty=1"
else
  curl -X POST "https://slack.com/api/chat.postMessage?token=$SLACK_TOKEN&channel=$CHANNEL_ID&text=Your%20license%20is%20here!&as_user=false&pretty=1"
fi
