#!/bin/bash
# Starts logstalgia for each defined server
#
set -u
set -e

# Default Logstalgia parameters
LOGS_PARAMS="--hide-paddle"
LOGS_WIN_SIZE="600x540"         # 600px is enough for 'Kiho Tres (AWS) to fit in title

# Get screen size using 'xrandr' if available. If there is several monitors, use the last one.
WDIV=3
HDIV=2
TBARH=10
if hash xrandr 2>/dev/null && hash bc 2>/dev/null; then
	RESOLUTION=$(xrandr | awk '/[0-9][0-9]\*/{print $1}' | tail -n 1)
	WIDTH=${RESOLUTION%x*}  # Deletes shortest match from BACK of the string
	HEIGHT=${RESOLUTION#*x} # Deletes shortest match fromn START of the string
	LOGS_WIN_SIZE="$(echo "$WIDTH / $WDIV" | bc)x$(echo "$HEIGHT / $HDIV - $TBARH" | bc)"
else
	echo "WARNING: Either 'xrandr' or 'bc' not installed -> using default windows size: $LOGS_WIN_SIZE"
fi

# Use associative array for server whose 'access_log' should be displayed
declare -A SERVERS=(
	['mcalpha']='/var/log/httpd/access_log'
	['mckiho']='/var/log/httpd/access_log'
	['mctres']='/var/log/nginx/access.log'  # $(ssh mctres ls "/var/log/nginx/*access.log")
)
declare -A SERVER_NAMES=(
	['mcalpha']='Kiho Alpha'
	['mckiho']='IsoKiho'
	['mctres']='Kiho Tres (AWS)'
)


# Using '!' is needed when looping THE KEYS of an associative array!
for server in "${!SERVERS[@]}"; do
	# NORMALLY you would use '"' around ALL variables but b/c we need to split at '\n' but not ' ' you DON'T
	IFS=$'\n' FILES=( ${SERVERS[$server]} )
	if (( ${#FILES[@]} == 0 )); then
		echo "ERROR: No log files specified for '$server'!" && continue
	fi
	NAME="${SERVER_NAMES[$server]}"
	echo "Starting Logstalgia for '$NAME: ${FILES[@]}'"

	# Remember to use '-t' with SSH - otherwise 'tail' stays up even after SSH connection is killed
	# No need(?) to '2>&1' b/c 'nohup' does that already
	if (( ${#FILES[@]} == 1 )); then
		nohup ssh -t "$server" tail -f "${FILES[0]}" | logstalgia -$LOGS_WIN_SIZE $LOGS_PARAMS --title "$NAME" > /dev/null &
	else
		echo "==> multitail here !!!"
		# http://seengee.co.uk/2012/09/08/using-multitail-for-monitoring-multiple-log-files/
		# --follow-all --mergeall --retry-all -D -w
		# multitail
		# -l "ssh root@REMOTE.IP.1 tail -f /usr/local/apache/logs/error_log"
		# -l "ssh root@REMOTE.IP.2 tail -f /usr/local/apache/logs/error_log"
	fi



done

unset -v SERVERS
unset -v FILES
