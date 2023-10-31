#!/usr/bin/env bash

file="$1"
devices_file="$2"
layer_items_key="$3"

tmpfile="$(mktemp)"

echo "Clearing file..."
< "$file" jq --arg key "$layer_items_key" 'getpath($key | split(".")[1:]) = []' > "$tmpfile"
cp "$tmpfile" "$file"

while read device; do
  echo "Adding DEVICE: $device"

  < "$file" jq --arg key "$layer_items_key" --arg device "$device" 'getpath($key | split(".")[1:]) +=
  [{
    "layerItemId": "\($device)@system",
    "layerName": "ipte-telemetry-device-uptime-seconds",
    "timestamp": 1584056267597,
    "layerItemData": {
      "@class": "com.amazonaws.services.bodca.local.producer.layeritemdata.TelemetryLayerItemData",
      "deviceName": "\($device)",
      "interfaceName": "system",
      "metricName": "deviceUptimeSeconds",
      "metricValue": "5000",
      "timestamp": 1584056267597
    }
  }]' > "$tmpfile"

  cp "$tmpfile" "$file"

done <"$devices_file"

rm "$tmpfile" || echo "$tmpfile already deleted."

