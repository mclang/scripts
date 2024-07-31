#!/bin/bash
#
# Script that starts Transmission BitTorrent client with Wireguard NAT-PMP port-forwarding.
# Keeps the NAT-PMP port open using `while` loop, so it is best to run this script in the background.
#
# For information how to setup Wireguard, check official ProtonVPN documentation:
#   https://protonvpn.com/support/port-forwarding-manual-setup/
#
# TODO:
# - Binding Transmission into WG interface.
# - Notifications using `dunstify`
# - Wireguard `PreDown` rule to kill Transmission
# - Maybe the presence of WG interface should be checked every second?
#
CLIENT_BIN="transmission-gtk"
CLIENT_CFG="${HOME}/.config/transmission/settings.json"
CLIENT_PID=""
WG_GATEWAY="10.2.0.1"
WG_INTFACE="$(ip link show | grep -oP 'wg[a-zA-Z0-9_\-]+')"
PUBLIC_PORT=""

# NOTE: These need to be set AFTER the above definitions, otherwise `e`
# with `pipefail` might hide errors in the sub shell commands!
set -euo pipefail

# Validity checks:
if ! command -v natpmpc >/dev/null 2>&1; then
	echo "ERROR: Command 'natpmpc' not found!"
	exit 1
fi
if ! command -v "$CLIENT_BIN" >/dev/null 2>&1; then
	echo "ERROR: Bittorrent client '$CLIENT_BIN' not found!"
	exit 1
fi
if [[ ! -e "$CLIENT_CFG" ]]; then
	echo "ERROR: Bittorrent config '$CLIENT_CFG' not found!"
	exit 1
fi
if pgrep -f "$CLIENT_BIN" > /dev/null; then
	echo "ERROR: '$CLIENT_BIN' is already running as PID '$(pgrep -f $CLIENT_BIN)'!"
	exit 1
fi
if [[ -z "$WG_INTFACE" ]]; then
	echo "ERROR: Wireguard interface not available!"
	exit 1
fi
# NOTE: Didn't find if this can be done using normal return value :/
if natpmpc -g "$WG_GATEWAY" | grep -q "FAILED"; then
	echo "ERROR: Wireguard port forwarding is not supported - check your configuration!"
	exit 1
fi


# Creating NAT-PMP port mappings for both UDP and TCP protocols.
# Record the public TCP port and change client settings accordingly.
PUBLIC_PORT=$(natpmpc -a 1 0 udp 60 -g "$WG_GATEWAY")
PUBLIC_PORT=$(natpmpc -a 1 0 tcp 60 -g "$WG_GATEWAY" | sed -n 's/.*port \([0-9]*\) protocol.*/\1/p')
if ! echo "$PUBLIC_PORT"| grep -Eq '^[0-9]{5}$'; then
	echo "ERROR: Invalid NAT-PMP public port '$PUBLIC_PORT'!"
	echo "==> Run 'natpmpc -a 1 0 tcp 60 -g "$WG_GATEWAY"' manually to troubleshoot"
	exit 1
fi
sed -i "s/\(\"peer-port\":\).*[0-9]*,/\1 ${PUBLIC_PORT},/" "$CLIENT_CFG"


# NOTES:
# - Trap EXIT so that also the bittorrent client is killed when this script dies.
# - Backgrounding of the client start command must be done INSIDE of the `eval` in order to get the right PID.
echo ""
echo "STARTING '$CLIENT_BIN' USING FOLLOWING WIREGUARD SETTINGS"
echo "- Gateway:     $WG_GATEWAY"
echo "- Interface:   $WG_INTFACE"
echo "- Public port: $PUBLIC_PORT"
trap "pkill -9 -f '$CLIENT_BIN'" EXIT
eval "$CLIENT_BIN > /dev/null 2>&1 &"
CLIENT_PID=$!
echo "==> DONE (PID: $CLIENT_PID)"
echo "STARTING NAT-PMP HEARTBEAT LOOP"
while true; do
	echo "$(date +'%F %T') :: Poking Wireguard NAT-PMP..."
	if ! pgrep -f "$CLIENT_BIN" > /dev/null; then
		echo "INFO: '$CLIENT_BIN' is NOT running -> STOPPING the heartbeat loop"
		break
	fi
	if ! ip link show | grep -q "$WG_INTFACE"; then
		echo "WARN: Wireguard interface '$WG_INTFACE' has disappeared!"
		echo "==> Stopping '$CLIENT_BIN' and the heartbeat loop"
		pkill -9 -f "$CLIENT_BIN"
		break
	fi
	natpmpc -a 1 0 udp 60 -g "$WG_GATEWAY" | grep 'Mapped public port'
	natpmpc -a 1 0 tcp 60 -g "$WG_GATEWAY" | grep 'Mapped public port'
	sleep 50
done
echo "DONE - NAT-PMP HEARTBEAT LOOP STOPPED"

