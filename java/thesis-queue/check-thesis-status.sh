#!/usr/bin/env bash

source $HOME/.utah

java -jar thesis-queue.jar | tail -n 1 > current-position

diff current-position last-position
if [ $? -ne 0 ]; then
  current=$(<current-position)
  curl -X POST "https://slack.com/api/chat.postMessage?token=$SLACK_TOKEN&channel=$CHANNEL_ID&text=Queue%20Position%20Updated%3A%20$current.&as_user=false&pretty=1"
  mv current-position last-position
fi
