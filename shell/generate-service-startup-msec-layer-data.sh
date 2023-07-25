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

  < "$file" jq --arg key "$layer_items_key" --arg device "$device" 'getpath($key | split(".")[1:]) +=
  [{
    "layerItemId": "\($device)@frr.service",
    "layerName": "ipte-telemetry-service-startup-msec",
    "timestamp": 1584056267597,
    "layerItemData": {
      "@class": "com.amazonaws.services.bodca.local.producer.layeritemdata.TelemetryLayerItemData",
      "deviceName": "\($device)",
      "interfaceName": "frr.service",
      "metricName": "systemdServiceStartupMsec",
      "metricValue": "5000",
      "timestamp": 1584056267597
    }
  }]' > "$tmpfile"

  cp "$tmpfile" "$file"

done <"$interfaces_file"

rm "$tmpfile" || echo "$tmpfile already deleted."

