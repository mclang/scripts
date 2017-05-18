#!/bin/bash
# Converts given mkv files with __embedded__ subtitles into __harsubbed__ mp4 files using ffmpeg.
# Uses hardlinking to overcome problem with spaces in filename of the source subtitle file.
#
set -u
set -e
shopt -s nullglob

for MKV in "$@"; do
	out="$(basename "$MKV" .mkv).mp4"
	echo "CONVERTING '$MKV''"
	cp -l "$MKV" input.mkv
	ffmpeg -i input.mkv -c:a copy -c:v libx264 -profile:v high -level:v 4.1 -preset medium -crf 23 -vf subtitles=input.mkv "$out"
	rm -f input.mkv
	echo "==> $out"
	echo ""
done
