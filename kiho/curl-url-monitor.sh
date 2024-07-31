#!/bin/bash
# Cannot be used b/c stops WHOLE script if e.g `curl` returns error :/
# set -euo pipefail

URL="https://cabler.kiho.fi/index.php"
LOG="ping-cabler_$(date --iso-8601).log"

{
while true; do
    DATE=$(date +"%Y-%m-%dT%H:%M:%S")
    HTTP_BODY="response-body_$DATE.html"
    HTTP_CODE=$(curl -s -o "$HTTP_BODY" -w "%{http_code}" --retry 5 --max-time 15 "$URL")
    CURL_RVAL=$?
    REBOOT=0

    if (( HTTP_CODE == 200 )); then
        REBOOT=1
        echo "$DATE - '$URL' is UP. Status code: '$HTTP_CODE'"
        rm "$HTTP_BODY"
    else
        echo "$DATE - '$URL' is DOWN. Status code: '$HTTP_CODE' (curl returned: '$CURL_RVAL')"
        if (( REBOOT == 1 )); then
            echo "==> REBOOTING THE SERVER!"
            # sudo reboot
        fi
    fi

    sleep 60
done
} | tee -a "$LOG"

