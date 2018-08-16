#!/bin/bash
#
# https://www.kirsle.net/wiki/PowerTOP-and-USB-Autosuspend
# https://hamwaves.com/usb.autosuspend/en/
#
# Disables USB auto-suspend for the configured devices. Does NOT survive
# reboot though, so you might be better of creating UDEV rules like this:
# ```
# # Bus 003 Device 007: ID 10f5:0651 Turtle Beach
# ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="10f5", ATTR{idProduct}=="0651", TEST=="power/control", ATTR{power/control}="on"
#
# # Bus 003 Device 006: ID 046d:c52b Logitech, Inc. Unifying Receiver
# ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c52b", TEST=="power/control", ATTR{power/control}="on"
# ```
# NOTE: The UDEV rules kick in only after connecting devices after into running computer!
#
set -u
set -e

declare -A DEVICES=(
	['Logitech M570']='/sys/bus/usb/devices/3-1.7/power/control'
	['Turtlebeach Impact 500']='/sys/bus/usb/devices/3-1.6/power/control'
)

for USBDEV in "${!DEVICES[@]}"; do
	UDEV_NAME="$USBDEV"
	CTRL_FILE="${DEVICES[$USBDEV]}"
	if [[ -f "$CTRL_FILE" ]]; then
		echo 'on' > "$CTRL_FILE"
	fi
done

