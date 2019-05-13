#!/bin/bash
# https://thetinhat.com/tutorials/misc/linux-vpn-drop-protection-firewall.html
# https://www.reddit.com/r/VPN/comments/2vxrey/is_there_a_way_to_set_up_ubuntu_so_that_it_will/comog21?utm_source=share&utm_medium=web2x
#
set -e
set -u

# TODO:
# - Loop interfaces and use the first 'tun' found
# - Use GW from the found 'tun' instead of static one
VPN_IF='tun0'
VPN_GATEWAYS=(
	# fi52.nordvpn.com.tcp
	"196.196.200.19"
	# fi65.nordvpn.com.tcp
	"196.196.201.197"
)


if ! ip addr show | grep -q "$VPN_IF"; then
	echo "OpenVPN interface '"$VPN_IF"' not found!"
	exit 1
fi

if command -v ufw >/dev/null 2>&1; then
	sudo ufw reset
	# Deny ALL normal network traffic
	sudo ufw default deny incoming
	sudo ufw default deny outgoing
	# Allow outgoing using VPN only
	sudo ufw allow out on "$VPN_IF" from any to any
	# Needed so that the **initial** connection to NordVPN servers can be established
	for VPNGW  in "${VPN_GATEWAYS[@]}"; do
		sudo ufw allow out from any to "$VPNGW"
	done
	sudo ufw enable
	sudo ufw status
else
	echo "Please install 'ufw' first"
fi

