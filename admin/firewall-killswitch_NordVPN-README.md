# NordVPN NordLynx Killswitch

**08.11.2021:**
At times NordLynx fails.

Then if NordVPN service is stopped before disconnecting it using `nordvpn d` command, it
may well happen that the killswitch rules in IPtables are **not** removed properly, which
results in not being able to connect outside LAN and restart NordVPN service.

Usually `sudo iptables --flush` helps to regain connectivity, but that also opens the
computer ports for possible attacs.

Thus, re-enable NordVPN when possible!

Snapshot of working IPtable rules (10.11.2021):
```
mclang@Zephyrus ~ > sudo iptables -S
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
-A INPUT -s 192.168.2.0/24 -i eth0 -j ACCEPT
-A INPUT -s 192.168.10.0/24 -i eth0 -j ACCEPT
-A INPUT -s 192.168.2.0/24 -i wlan0 -j ACCEPT
-A INPUT -s 192.168.10.0/24 -i wlan0 -j ACCEPT
-A INPUT -i wlan0 -j DROP
-A OUTPUT -d 192.168.2.0/24 -o eth0 -j ACCEPT
-A OUTPUT -d 192.168.10.0/24 -o eth0 -j ACCEPT
-A OUTPUT -d 192.168.2.0/24 -o wlan0 -j ACCEPT
-A OUTPUT -d 192.168.10.0/24 -o wlan0 -j ACCEPT
-A OUTPUT -o wlan0 -j DROP
```

**NOTE:** Use `iptables -L --line-numbers` to get line numbers for easy deletion


NordVPN Settings:
```
> nordvpn settings
Technology: NORDLYNX
Firewall: enabled
Kill Switch: enabled
CyberSec: disabled
Notify: disabled
Auto-connect: enabled
IPv6: disabled
DNS: disabled
Whitelisted subnets:
  192.168.2.0/24
  192.168.10.0/24
```

