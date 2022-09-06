#!/bin/bash
# https://thetinhat.com/tutorials/misc/linux-vpn-drop-protection-firewall.html
# https://www.reddit.com/r/VPN/comments/2vxrey/is_there_a_way_to_set_up_ubuntu_so_that_it_will/comog21?utm_source=share&utm_medium=web2x
#
set -e
set -u

if hash /usr/sbin/ufw 2>/dev/null; then
	sudo ufw reset
	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	sudo ufw enable
	sudo ufw status
else
	echo "Please install 'ufw' first"
fi

