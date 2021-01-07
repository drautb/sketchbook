#!/usr/bin/env bash

add_14_days() {
  date -v+14d -jf "%Y-%m-%d" "$1" +"%Y-%m-%d" # Add 14 days to whatever date was given.
}

ymd-to-seconds() {
  date -jf "%Y-%m-%d" "$1" +"%s"
}

next-sprint-end() {
  today=$(date +"%Y-%m-%d")
  next_end="2020-04-14"
  while [[ $(ymd-to-seconds "$today") -gt $(ymd-to-seconds "$next_end") ]]; do
    tmp_next_end=$(add_14_days "$next_end")
    next_end="$tmp_next_end"
  done
  echo "$next_end"
}

fs-logs-today() {
  # $FS_ONEDRIVE/logs/<year>/Sprint-<spring end date>/<Day>/<Time>-suffix
  year=$(date +"%Y")
  day=$(date +"%Y-%m-%d-%a")
  time=$(date +"%H-%M-%S")
  dir="$FS_ONEDRIVE/logs/$year/Sprint-$(next-sprint-end)/$day"
  mkdir -p "$dir"
  echo "$dir/$time"
}

function run_tests {
  single="$1"
  combo="$2"
  printf "*****************************\n"
  printf "*** SINGLE: $single\n"
  printf "*** COMBO:  $combo\n"
  printf "*****************************\n"
  java -Dsingle.word.edit.distance="$single" -Dcombo.word.edit.distance="$combo" -Xmx8G -jar ../nlp-ws/target/nlp-ws.jar > /usr/local/var/log/fs/app.json 2>&1 &
  printf "Waiting 20 seconds for service to start up...\n"
  sleep 20
  printf "Done. Starting tests...\n"
  mvn -Denvironment=local -Dtest="DexterScoringATest#scoreDexter_venezuela_release1_new_gedcomx_converter,ImageStuffToGedcomxScoringATest" verify | tee "$(fs-logs-today)-nlp-ATs-es-edit-distance-single-$single-combo-$combo-test.txt"
  kill %1
}

run_tests 3 2
run_tests 4 2
run_tests 5 2
run_tests 3 3
run_tests 4 3
run_tests 5 3
