#!/usr/bin/env bash

file="$1"
interfaces=(
  a-r1@bond-ab-1-1
  a-r2@bond-ab-2-1
  a-r2@bond-ab-2-2
  a-r2@bond-ac-2-1
  a-r2@bond-ad-2-1
  b-r1@bond-ba-1-1
  b-r1@bond-ba-1-2
  b-r1@bond-bb-1-2
  b-r2@bond-ba-2-2
  b-r2@bond-bb-2-1
  b-r2@bond-bc-2-2
  c-r1@bond-ca-1-2
  c-r1@bond-cc-1-2
  c-r1@bond-cd-1-1
  c-r1@bond-cd-1-2
  c-r2@bond-cb-2-2
  c-r2@bond-cc-2-1
  c-r2@bond-ce-2-1
  d-r1@bond-da-1-2
  d-r1@bond-dc-1-1
  d-r1@bond-dd-1-2
  d-r2@bond-dc-2-1
  d-r2@bond-dd-2-1
  d-r2@bond-de-2-2
  e-r1@bond-ec-1-2
  e-r2@bond-ed-2-2
)

tmpfile="$(mktemp)"
echo "Clearing file..."
< "$file" jq '.allUp.layerItems = []' > "$tmpfile"
cp "$tmpfile" "$file"

for i in "${interfaces[@]}"; do
  device="$(echo $i | tr "@" "\n" | head -n1)"
  interface="$(echo $i | tr "@" "\n" | tail -n1)"

  echo "Adding DEVICE: $device  INTERFACE: $interface"

  for proto in 4 6; do
    < "$file" jq --arg device "$device" --arg interface "$interface" --arg proto "$proto" '.allUp.layerItems += 
    [{
      "layerItemId": "\($device)@\($interface)@ipv\($proto)",
      "layerName": "ipte-telemetry-bgp-peer-status",
      "timestamp": 1584056267597,
      "layerItemData": {
        "deviceName": "\($device)",
        "interfaceName": "\($interface)",
        "metricName": "bgpPeerSessionStatusIpv\($proto)",
        "metricValue": "Established",
        "timestamp": 1584056267597
      }
    }]' > "$tmpfile"

    cp "$tmpfile" "$file"
  done

done

rm "$tmpfile" || echo "$tmpfile already deleted."
