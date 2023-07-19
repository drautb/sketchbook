#!/usr/bin/env bash

file="$1"
interfaces_file="$2"
layer_items_key="$3"

tmpfile="$(mktemp)"

echo "Clearing file..."
< "$file" jq --arg key "$layer_items_key" 'getpath($key | split(".")[1:]) = []' > "$tmpfile"
cp "$tmpfile" "$file"

while read i; do
  device="$(echo $i | tr "@" "\n" | head -n1)"
  interface="$(echo $i | tr "@" "\n" | tail -n1)"

  echo "Adding DEVICE: $device  INTERFACE: $interface"

  for proto in 4 6; do
    < "$file" jq --arg key "$layer_items_key" --arg device "$device" --arg interface "$interface" --arg proto "$proto" 'getpath($key | split(".")[1:]) += 
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

done <"$interfaces_file"

rm "$tmpfile" || echo "$tmpfile already deleted."
