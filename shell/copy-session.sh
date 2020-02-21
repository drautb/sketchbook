#!/usr/bin/env sh

sessionId=$(< "$HOME/.paas-portal" jq -r '.session.sessionId')
system=$(uname -s)

if [ "$system" = "Darwin" ]; then
  echo "$sessionId" | pbcopy
elif [ "$system" = "Linux" ]; then
  copyq add "$sessionId"
  copyq copy "$sessionId"
fi
