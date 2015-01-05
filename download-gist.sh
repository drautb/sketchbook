#!/usr/bin/env sh

# This script lets you easily download a gist by giving a portion of the
# gist description to match, and a destination filename. It requires that
# the gist gem have been installed. (gem install gist)

set -x

MATCHER=$1
FILENAME=$2

function get_gist_url() {
  local original_url
  original_url=$(gist --list | sed -n "s/^\\(http.*\\)\\ .*$MATCHER.*$/\1/p")
  echo $(echo $original_url | sed 's/\.com\//\.com\/drautb\//')/raw
}

curl -L "$(get_gist_url)" > "$FILENAME"


