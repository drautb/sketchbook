#!/usr/bin/env sh

cat ~/$1-env | grep AWS_PASSWORD | sed -E 's/.*="(.*)"$/\1/g' | sed -E 's/\\"/"/g' | pbcopy
