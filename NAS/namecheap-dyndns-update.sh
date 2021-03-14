#!/bin/bash

## Namecheap DDNS update client for Synology DSM 6
## Written by Ian Harrier
## https://blog.harrier.us/updating-namecheap-ddns-from-synology-dsm-6/

###
# Variables
# These need to be customized to your environment
#
# FQDN
#   The FQDN of the (A) record to be updated
#   Supports either 'domain.tld' or 'subdomain.domain.tld'
# PASSWORD
#   The DDNS update password from Namecheap
# NAME_SERVER
#   The DNS server used to resolve the DDNS (A) record
#   Recommended to use one of the domain's name servers
###

FQDN='subdomain.domain.tld'  
PASSWORD='<secret password from Namecheap admin console>'  
NAME_SERVER='dns1.registrar-servers.com'

###
# Retrieve the current public IPv4 address
###

# IPv4_CURRENT=$(nslookup myip.opendns.com resolver1.opendns.com | awk '/^Address: / { print $2 }')
IPv4_CURRENT=$(curl ifconfig.me/ip)
if [[ $IPv4_CURRENT =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "[I] The current IPv4 address is '$IPv4_CURRENT'"
else
	echo "[E] Unable to retrieve valid IPv4 address from 'opendns.com'. Exiting..."
	exit 1
fi


###
# Retrieve the reported public IPv4 address from the DDNS entry
###

IPv4_DDNS=$(nslookup $FQDN $NAME_SERVER | awk '/^Address: / { print $2 }')
if [[ $IPv4_DDNS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "[I] The DDNS (A) record reports '$IPv4_DDNS'"
else
	echo "[E] Unable to resolve '$FQDN' using name server '$NAME_SERVER'. Exiting..."
	exit 1
fi

###
# Compare the results
###

if [[ "$IPv4_CURRENT" == "$IPv4_DDNS" ]]; then
	echo -n "[I] IPv4 addresses match. No need to update. Exiting..."
	exit 0
else
	echo "[W] IPv4 addresses DO NOT match. Need to update."
fi

###
# Generate $HOST and $DOMAIN
###

# If $FQDN is in the format 'domain.tld' (i.e. one occurrence of '.')
if [[ $(echo $FQDN | awk 'BEGIN{FS="."} {print NF?NF-1:0}') == 1 ]]; then
	HOST='@'
	DOMAIN=$FQDN
fi

# If $FQDN is in the format 'subdomain.domain.tld' (i.e. two occurrences of '.')
if [[ $(echo $FQDN | awk 'BEGIN{FS="."} {print NF?NF-1:0}') == 2 ]]; then
	HOST=$(echo $FQDN | awk -F "." '{print $1}')
	DOMAIN=$(echo $FQDN | awk -F "." '{print $2 "." $3}')
fi

###
# Update DDNS
###

echo "[I] Updating '$FQDN' to '$IPv4_CURRENT'"
UPDATE_RESULT=$(curl -s "https://dynamicdns.park-your-domain.com/update?host=$HOST&domain=$DOMAIN&password=$PASSWORD&ip=$IPv4_CURRENT")

###
# Report error(s)
###

UPDATE_ERRORS=$(echo $UPDATE_RESULT | sed -n "s/.*<ErrCount>\(.*\)<\/ErrCount>.*/\1/p")

if [[ $UPDATE_ERRORS -gt 0 ]]; then
	echo "[E] There were $UPDATE_ERRORS error(s):"
	for (( i = 1; i <= $UPDATE_ERRORS; i++ )); do
		echo -n " $i. "
		echo $UPDATE_RESULT | sed -n "s/.*<Err$i>\(.*\)<\/Err$i>.*/\1/p"
	done
	echo "[I] Exiting..."
else
	echo "[I] Update successful. Exiting..."
fi

exit 1

