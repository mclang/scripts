#!/bin/bash
# Changes desktop background using Nitrogen.
# Can be used directly, or by using systemd user service/timer files
# defined in `$HOME/.config/systemd/user`
#
BACKGROUNDS="/home/mclang/Pictures/Wallpapers"
if [[ ! -d "$BACKGROUNDS" ]]; then
	echo "ERROR: Directory '$BACKGROUNDS' does not exist!"
	exit 1
fi
if ! hash xrandr 2>/dev/null; then
	echo "ERROR: Command 'xrandr' cannot be found!"
	exit 1
fi
if ! hash nitrogen 2>/dev/null; then
	echo "ERROR: Command 'nitrogen' cannot be found!"
	exit 1
fi
for HEAD in `xrandr --listactivemonitors | sed -n 's/\s*\([0-9]\):\s*.*/\1/p'`; do
	nitrogen --head=$HEAD --set-zoom-fill --random "$BACKGROUNDS" 2>/dev/null
done

