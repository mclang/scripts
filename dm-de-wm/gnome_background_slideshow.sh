#!/bin/bash
# Changes Gnome 3 background image to random one found from given directory
#
# Can be used directly, or by calling it from `/etc/cron.d/gnome_background_slideshow` like this:
# */30 * * * * <user> /<path>/gnome_background_slideshow.sh > /dev/null 2>&1
#
# or by using systemd user service/timer files defined in `$HOME/.config/systemd/user`.
# Check `$HOME/.config/systemd/user/README.md` for more information.
#

# Check that we are running Gnome:
if [[ "$DESKTOP_SESSION" != "gnome" && "$XDG_SESSION_DESKTOP" != "gnome" ]]; then
	exit 0
fi

# This is needed so that 'gsettings' work when run from cron.
# Use FULL 'gnome-session-binary' match so that e.g instance started by GDM is skipped
if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
	PID=$(pgrep -fx /usr/lib/gnome-session-binary)
	export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$PID/environ | cut -d= -f2-)
fi

# Select random image from given folder or its subfolder
DIR="/home/mclang/Pictures/Wallpapers"
PIC=$(find "$DIR" -type f | /usr/bin/shuf -n1)

# Use 'gsettings' to set new background image:
gsettings set org.gnome.desktop.background picture-uri "file://$PIC"

