#!/bin/bash
# https://thetinhat.com/tutorials/misc/linux-vpn-drop-protection-firewall.html
# https://www.reddit.com/r/VPN/comments/2vxrey/is_there_a_way_to_set_up_ubuntu_so_that_it_will/comog21?utm_source=share&utm_medium=web2x
#
set -e
set -u

# TODO:
# - Loop interfaces and use the first 'tun' found
# - Use GW from the found 'tun' instead of static one
VPNIF='tun0'
VPNGW='196.196.200.51'

if ! ip addr show | grep -q "$VPNIF"; then
	echo "OpenVPN interface '"$VPNIF"' not found!"
	exit 1
fi

if hash /usr/sbin/ufw 2>/dev/null; then
	sudo ufw reset
	# Deny ALL normal network traffic
	sudo ufw default deny incoming
	sudo ufw default deny outgoing
	# Allow outgoing using VPN only
	sudo ufw allow out on "$VPNIF" from any to any
	# Needed so that initial connection to 'fi50.nordvpn.com' can be done
	sudo ufw allow out from any to "$VPNGW"
	sudo ufw enable
	sudo ufw status
else
	echo "Please install 'ufw' first"
fi

