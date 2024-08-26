#!/usr/bin/env bash

SITE="$1"

function mcurl() {
  curl "$@" -L --cookie ~/.midway/cookie --cookie-jar ~/.midway/cookie
}

echo "NSM Region Information:"
mcurl -s "https://nsm-iad.amazon.com/_search_site_mapping?site=$SITE"
echo ""

echo "LCI Hosts for Site:"
mcurl -s "https://code.amazon.com/packages/LCIApplicationMetadata/blobs/mainline/--/configuration/site_allocation/$SITE.alloc.yaml?raw=1" | yq -c 'to_entries[] | select(.value.app.name == "ariadne") | {"num":.value.app.instance_num, "host": .key}' | sort
echo ""

echo "Ariadne Constants:"
mcurl -s "https://code.amazon.com/packages/AriadneConstants/blobs/mainline/--/constants/sites.json?raw=1" | jq --arg site "$SITE" '.sites[] | select(.siteId == $site)'
echo ""

echo "LCI Loopback IPs:"
mcurl -s "https://code.amazon.com/packages/LCISiteMetadata/blobs/mainline/--/configuration/metadata/$SITE.metadata.yaml?raw=1" | yq -c '.racks[].servers | to_entries[] | {"Host":.key, "Loopback":.value.loopback_ip}'
