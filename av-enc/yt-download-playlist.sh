#!/bin/bash
# Downloads given playlist using Youtube-dl:
# https://github.com/ytdl-org/youtube-dl
#
# About selecting downloaded audio/video format:
# https://github.com/ytdl-org/youtube-dl#user-content-format-selection-examples
#
# Usefull examples:
# - `youtube-dl -F <video url>`
# - `youtube-dl -f 247+251 <video url>`
# - `youtune-dl -f 'bestvideo[ext=webm][height<=1080]+bestaudio[ext=webm]'`
#
# Downloads ONLY videos released AFTER given date (inclusive) if it is provided as second parameter.
#
set -e
set -u
set -o pipefail

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

