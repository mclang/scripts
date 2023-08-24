#!/bin/bash
# Start/Stop Kiho v3 worktime
# https://developers.kiho.fi/api/#tag/WorktimePunch/paths/~1punch/post
#
set -e
set -u

function print_usage ()
{
	local script="$(basename $(readlink -nf $0))"
	echo "USAGE:" >&2
	echo "    $ ${script}                      -> ???" >&2
	echo "    $ ${script} start  [description] -> start working (punch in). works with BREAK also" >&2
	echo "    $ ${script} stop   [description] -> stop working (punch out)" >&2
	echo "    $ ${script} break                -> start a break" >&2
	echo "" >&2
	exit 1
}

function parse_punch_type ()
{
	shopt -s nocasematch
	if [[ $1 == "break" ]]; then
		echo "BREAK"
	elif [[ $1 == "start" || $1 == "login" ]]; then
		echo "LOGIN"
	elif [[ $1 == "stop"  || $1 == "logout" ]]; then
		echo "LOGOUT"
	else
		echo "ERROR: Invalid punch type '$1'" >&2
		print_usage
	fi
}

declare -A CONFIGS=()
function read_config ()
{
	local real_name="$(readlink -nf $0)"
	local real_path="$(dirname "$real_name")"
	local cfg_file="$real_path/$(basename "$real_name" .sh).cfg"

	if [[ ! -e "$cfg_file" ]]; then
		echo "ERROR: Config file '$cfg_file' not found" >&2
		return 1
	fi

	IFS="="
	while read -r name value; do
		# Skip comment and empty lines
		if [[ $name =~ ^# || $name == "" || $value == "" ]]; then
			continue
		fi
		# Trim possible '"' chars from the value
		CONFIGS[$name]="${value//\"/}"
	done < "$cfg_file"
}

# Default payload values
DESCRIPTION="$(hostname)"   # Possible parameter value given will be appended
LOGIN_LOGOUT_INFO=''
PUNCH_TYPE='LOGIN'          # LOGIN | LOGOUT | BREAK
PUNCH_STAMP=$(date --iso-8601=seconds)

# Parse punch type and possible description
if [[ ! -z "$@" ]]; then
	PUNCH_TYPE="$(parse_punch_type "$1")"
	if (( $# >= 2 )); then
		DESCRIPTION+=": $2"
	fi
fi


# Try to read configuration
if ! read_config; then
	exit 1
fi
API_URL='https://v3.kiho.fi/api/v1/punch'
API_KEY="${CONFIGS['API_KEY']}"
CUSTOMER_COST_CENTRE="${CONFIGS['CUSTOMER_COST_CENTRE']}"


# BREAK needs only 'type' and timestamps, whereas LOGIN and LOGOUT also
# need 'customerCostcentre' and optionaly 'description' values.
if [[ $PUNCH_TYPE != "BREAK" ]]; then
	LOGIN_LOGOUT_INFO="$(cat <<EOF
		"description": "${DESCRIPTION}",
		"customerCostcentre": { "id": ${CUSTOMER_COST_CENTRE} },
EOF
)"
fi

JSON_PAYLOAD="$(cat <<EOF
{
	"newPunch": {
		"type": "${PUNCH_TYPE}",
${LOGIN_LOGOUT_INFO}
		"timestamp": "$PUNCH_STAMP",
		"realTimestamp": "$PUNCH_STAMP"
	}
}
EOF
)"

# echo -e "JSON PAYLOAD:\n$JSON_PAYLOAD"
# exit 0

# URL="https://v3.kiho.fi/api/v1/punch?mode=latest"
# URL="https://v3.kiho.fi/api/v1/punch?orderBy=timestamp+DESC&pageSize=1"
# URL="https://v3.kiho.fi/api/users/27874/punch?mode=latest"
# echo "RUNNING '$URL'"
# /usr/bin/curl \
# 	-X GET \
# 	-H "Authorization: $API_KEY" \
# 	-H "Content-Type: application/json" \
# 	"$URL"
# exit 0

# Use curl to POST data:
# -X: Specify request type, here POST
# -s: Make curl silent, i.e do not print progress bars and the like
# -o /dev/null: Redirect response body into '/dev/null'
# -D -:         Dump headers into file, here stdout
# -H: Specify HTTP headers
# -d: Response data, JSON body
/usr/bin/curl \
	-X POST \
	-s -o /dev/null -D - \
	-H "Authorization: $API_KEY" \
	-H "Content-Type: application/json" \
	-d "$JSON_PAYLOAD" \
	$API_URL
exit 0

