#!/usr/bin/env bash

set -eux

# Starts up a sandbox environment for HAProxy. Uses `haproxy.cfg` as its current
# configuration.

# Stop old stuff
pkill racket || echo "No racket processes running"
pkill haproxy || echo "No HAProxy processes running"

sleep 3

# Start echo port backends
ports=("8110" "8120" "8130" "8140" "8150")

for port in "${ports[@]}"; do
  racket echo.rkt -p "$port" &
done

haproxy -f haproxy.cfg
