#!/bin/bash
# Changes Gnome 3 background image to random one found from given directory
#
# Can be called from `/etc/cron.d/gnome_background_slideshow` like this:
# */30 * * * * <user> /<path>/gnome_background_slideshow.sh > /dev/null 2>&1
#

# This is needed so that 'gsettings' work when run from cron:
if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
	PID=$(pgrep gnome-session)
	export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$PID/environ | cut -d= -f2-)
fi

# Select random image from given folder or its subfolder
DIR="/home/mclang/Shares/Syncthing/mastercom-kiho/wallpapers"
PIC=$(find "$DIR" -type f | /usr/bin/shuf -n1)

# Use 'gsettings' to set new background image:
gsettings set org.gnome.desktop.background picture-uri "file://$PIC"

