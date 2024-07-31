#!/bin/bash
#
# Changes desktop background using `swaymsg`/`swaybg`.
#
# Can be used directly, or by using systemd USER service/timer files
# defined in `$HOME/.config/systemd/user`
#
# TODO:
# - Maybe try https://github.com/xyproto/wallutils
# - Use `swaymsg -t get_outputs` to set different backgrounds for different monitors
# - https://github.com/swaywm/swaybg/issues/64
#
# NOTE: Cannot be enabled b/c `pidof swaybg` errors if process not found!
# set -euo pipefail

WALLPAPERS="/home/mclang/Pictures/Wallpapers"
if [[ ! -d "$WALLPAPERS" ]]; then
	echo "ERROR: Directory '$WALLPAPERS' does not exist!"
	exit 1
fi
if ! hash shuf 2>/dev/null; then
	echo "ERROR: Command 'shuf' cannot be found!"
	exit 1
fi
if ! hash swaybg 2>/dev/null; then
	echo "ERROR: Command 'swaybg' cannot be found!"
	exit 1
fi
if ! hash swaymsg 2>/dev/null; then
	echo "ERROR: Command 'swaymsg' cannot be found!"
	exit 1
fi
if [[ -z "$SWAYSOCK" ]]; then
	echo "INFO: Skipping desktop background change b/c 'SWAYSOCK' environment variable NOT defined"
	exit 0
fi

BACKGROUND="$(find "$WALLPAPERS" -name '*.jpg' -o -name '*.png' | shuf -n1)"

# EITHER (shows grey screen for a moment...):
swaymsg -s "$SWAYSOCK" output '*' bg "$BACKGROUND" fill '#000000'

# OR (does not work as systemd user service...):
#OLD_PIDS="$(pidof swaybg)"
#swaybg -i "$BACKGROUND" -m fill -o '*' &
#if [[ -n "$OLD_PIDS" ]]; then
#	kill $OLD_PIDS
#fi

