#!/bin/bash
# Downloads given playlist using Youtube-dl:
# https://github.com/ytdl-org/youtube-dl
#
# About selecting downloaded audio/video format:
# - https://github.com/yt-dlp/yt-dlp
# - https://www.ditig.com/yt-dlp-cheat-sheet
# - https://roundproxies.com/blog/yt-dlp
#
# Useful examples:
# - List formats:        `yt-dlp -F <video url>`
# - List subtitles:      `yt-dlp --list-subs <video url>`
# - Download&Mux V+A:    `yt-dlp -f 247+251 <video url>`
# - Best max 1080p WebM: `yt-dlp -f 'bv[ext=webm][height<=1080]+ba[ext=webm]'`
# - Write subs into external file: `yt-dlp --sub-lang en --write-subs`
# - Embed subs into video file:    `yt-dlp --sub-lang en --embed-subs`
#
# Fallout Season One as 1080p webm with EN & FI auto-subtitles (vtt files):
# ```
# $ yt-dlp -f "bv[ext=webm]+ba[ext=webm]" -i -o "%(title)s.%(ext)s" \
#   --cookies-from-browser firefox --download-archive archive.txt --no-overwrites --mark-watched \
#   --write-auto-subs --sub-langs "en,fi" --sleep-subtitles 60 \
#   'https://www.youtube.com/playlist?list=PLWz2DO39R-NX9gYByO7231inaftQYqI8v'
# ```
#
# Downloads ONLY videos released AFTER given date (inclusive) if it is provided as second parameter.
#
set -euo pipefail

function print_usage ()
{
	local script="$(basename "$(readlink -nf "$0")")"
	echo "USAGE:" >&2
	echo "    $ ${script} <playlist url> [<YYYYMMDD date>]" >&2
	echo "" >&2
	exit 1
}


if ! hash youtube-dl 2>/dev/null; then
	echo "ERROR: Command 'youtube-dl' cannot be found!"
	exit 1
fi

case $# in
1)
	PLAYLIST_URL="$1"
	DATE_AFTER=""
;;

2)
	PLAYLIST_URL="$1"
	DATE_AFTER="$2"
;;

*)
	echo "ERROR: Wrong number of parameters!"
	print_usage
esac

if [[ -e "$DATE_AFTER" ]]; then
	YTDL_CMD="youtube-dl '$PLAYLIST_URL'"
else
	YTDL_CMD="youtube-dl --dateafter '$DATE_AFTER' '$PLAYLIST_URL'"
fi

echo "### STARTING PLAYLIST DOWNLOAD ###"
echo "- PLAYLIST URL: '$PLAYLIST_URL'"
echo "- DATE AFTER:   '$DATE_AFTER'"
echo "==> Running '$YTDL_CMD'..."

