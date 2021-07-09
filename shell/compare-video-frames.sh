#!/usr/bin/env bash

# Simple script to overlay two frames from a video into a single image.

input_video="$1"
t1="$2"
t2="$3"
output_file="$4"

function extract_frame() {
	ffmpeg -hide_banner -loglevel warning -ss "$1" -i "$2" -vframes 1 "$3"
}

f1="$(mktemp).png"
f2="$(mktemp).png"

extract_frame "$t1" "$input_video" "$f1"
extract_frame "$t2" "$input_video" "$f2"

composite -blend 50% "$f1" "$f2" "$output_file"

