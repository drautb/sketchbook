#!/usr/bin/env bash

# Helper script to download all bodca layers suitable for loading by Java code.
# Used to prepare layers for loading in BTNGControllerMocks

set -e

stage="$1"
site="$2"

tmpfile="$(mktemp)"

aws s3 cp --quiet "s3://ariadne-iris-$stage-$site/${site}_reconciled_latest_snapshot_completed.json" \
  "$tmpfile" \
  --profile "$site"

prefix="$(< "$tmpfile" jq -r '.key_prefix')"
echo "Syncing files from latest reconciled snapshot prefix: $prefix"

aws s3 sync --quiet "s3://ariadne-iris-$stage-$site/$prefix/" . --profile "$site"

echo "Downloading current topology layer via bastion..."
airport="$(echo "$site" | tr "[:lower:]" "[:upper:]" | sed 's/[0-9]//g')"
host=$(expand-hostclass ARIADNE-BASTION-PROD-"${airport}" --hosts-only | head -n1)
ssh "$host" "sudo rm /tmp/ipte-topology.json && sudo -u ariadsvc /apollo/bin/env -e Ariadne-Bastion ariadne-cli bodca-local -s $site backup -l ipte-topology && sudo chmod 644 /tmp/ipte-topology.json"
scp "$host:/tmp/ipte-topology.json" .

echo "Updating type labels..."
temp=$(mktemp)
while IFS= read -r file; do
  < "$file" sed 's/__type/@class/g' | sed 's/#/./g' | sed 's/\([0-9]\)\.\([0-9]\)/\1\2/g' | jq > "$temp"
  mv "$temp" "$file"
done <<<"$(ls ./*.json)"

echo "Updating topology timestamps..."
sed -i 's/"[A-Z][a-z]\{2\}.*[0-9]\{4\}.*[AP]M"/"2000000000000"/g' ./ipte-topology.json

echo "Adding type annotations to topology..."
< ipte-topology.json jq '.layerItems |= map(if (.layerItemId | contains("br-ariadne-")) then .layerItemData += {"@class": "com.amazonaws.services.bodca.local.producer.layeritemdata.TopologyLayerControllerItemData"} else if (.layerItemId | contains("bond")) then .layerItemData += {"@class": "com.amazonaws.services.bodca.local.producer.layeritemdata.TopologyLayerLinkItemData"} else .layerItemData += {"@class": "com.amazonaws.services.bodca.local.producer.layeritemdata.TopologyLayerNodeItemData"} end  end)' > "$temp"
mv "$temp" ipte-topology.json

echo "Done."
