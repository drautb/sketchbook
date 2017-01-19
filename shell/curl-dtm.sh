#!/usr/bin/env sh

# This script just automates the nastiness of having to manually generate
# the authorization header for HTTP requests to DTM.

AUTH_TOKEN=$(java Encrypter "keystore.jks")

curl -H "Authorization: Bearer component-name:$AUTH_TOKEN" "$@"



