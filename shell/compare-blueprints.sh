#!/usr/bin/env bash

set -eux

yq --version
jq --version

yq . "$1" > "/tmp/$1.json"
yq . "$2" > "/tmp/$2.json"

jq --argfile first "/tmp/$1.json" --argfile second "/tmp/$2.json" -n '$first == $second'
