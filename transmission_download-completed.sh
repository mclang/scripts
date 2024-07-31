#!/bin/bash
#
# Script that does things after torrent download is completed.
# https://github.com/transmission/transmission/blob/main/docs/Scripts.md
#
# TODO:
# - Convert DEBUG/TEST to use `--debug` and `--test` (getopts)
#

ISOFILES_DIR="$HOME/Downloads/ISOs"
LOG_FILE="$HOME/Downloads/torrents/download-completed.log"
if [[ "$1" == "TEST" ]]; then
	TORRENTS_DIR='/home/mclang/Downloads/torrents/completed/'
	# TORRENT_NAME='kali-linux-2024.2-installer-amd64.iso'
	# TORRENT_NAME='Fedora-Sway-Live-x86_64-39'
	TORRENT_NAME='tails-amd64-6.0-img'
else
	TORRENTS_DIR="$TR_TORRENT_DIR"
	TORRENT_NAME="$TR_TORRENT_NAME"
fi
if [[ -d "$TORRENTS_DIR/$TORRENT_NAME" ]]; then
	TORRENT_TYPE="DIR"
elif [[ -e "$TORRENTS_DIR/$TORRENT_NAME" ]]; then
	TORRENT_TYPE="${TORRENT_NAME##*.}"
else
	TORRENT_TYPE="n/a"
fi

if [[ "$1" == "TEST" || "$1" == "DEBUG" ]]; then
	cat <<- EOT >> "$LOG_FILE"
		$(date +'%F %T')
		Target ISO dir: '$ISOFILES_DIR'
		Torrent name:   '$TORRENT_NAME'
		Torrent type:   '$TORRENT_TYPE'
		Torrent path:   '$TORRENTS_DIR/$TORRENT_NAME'
		$(env | grep 'TR_')
EOT
fi

# NOTE: These need to be set AFTER the above definitions, otherwise `e`
# with `pipefail` might hide errors in the sub shell commands!
set -euo pipefail


# Validity checks:
ERRORS=()
if [[ -z "$TORRENTS_DIR" ]]; then
	ERRORS+=("Variable 'TORRENTS_DIR' is empty!")
elif [[ ! -d "$TORRENTS_DIR" ]]; then
	ERRORS+=("Torrents dir  '$TORRENTS_DIR' does not exist!")
fi
if [[ ! -d "$ISOFILES_DIR" ]]; then
	ERRORS+=("Target ISO dir '$ISOFILES_DIR' does not exist!")
fi
if [[ ! -e "$TORRENTS_DIR/$TORRENT_NAME" ]]; then
	ERRORS+=("Torrent '$TORRENTS_DIR/$TORRENT_NAME' does not exist!")
fi
{
	if (( ${#ERRORS[@]} > 0 )); then
		echo "$(date +'%F %T') :: UNRECOVABLE ERRORS:"
		for err in "${ERRORS[@]}"; do
			echo "- $err"
		done
		echo ""
		exit 1
	fi
} | tee -a "$LOG_FILE"


# Do things as needed according to lower case file extension:
{
	echo "$(date +'%F %T') :: Downloading '$TORRENT_NAME' completed"
	case "${TORRENT_TYPE,,}" in
		'dir')
			echo "==> Torrent is a directory - linking IMG/ISO files using 'find'"
			find "$TORRENTS_DIR/$TORRENT_NAME" \( -iname '*.img' -o -iname '*.iso' \) -exec ln "{}" "$ISOFILES_DIR/" \;
			;;
		'img') ;&
		'iso')
			echo "==> Hard-linking into '$ISOFILES_DIR/' directory"
			ln "$TORRENTS_DIR/$TORRENT_NAME" "$ISOFILES_DIR/"
			;;
		*)
			echo "==> No post download logic specified"
			;;
	esac
} >> "$LOG_FILE" 2>&1
