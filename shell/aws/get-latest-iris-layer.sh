#!/usr/bin/env bash

set -e

stage="$1"
site="$2"
layer="$3"

tmpfile="$(mktemp)"

aws s3 cp --quiet "s3://ariadne-iris-$stage-$site/${site}_reconciled_latest_snapshot_completed.json" \
  "$tmpfile" \
  --profile "$site"

prefix="$(< "$tmpfile" jq -r '.key_prefix')"

aws s3 cp --quiet "s3://ariadne-iris-$stage-$site/$prefix/$layer.json" \
  "$tmpfile" \
  --profile "$site"

/bin/cat "$tmpfile"


