#!/bin/bash
# Simple downloader for Yle Areena podcasts.
# Maybe try 'yle-dl' next time:
# https://github.com/aajanki/yle-dl
#
set -ueo pipefail

EPISODES=(
	"https://areena.yle.fi/1-72429050"
	"https://areena.yle.fi/1-72428477"
	"https://areena.yle.fi/1-72429736"
	"https://areena.yle.fi/1-72429985"
	"https://areena.yle.fi/1-72430172"
	"https://areena.yle.fi/1-72430423"
	"https://areena.yle.fi/1-72430610"
	"https://areena.yle.fi/1-72430867"
	"https://areena.yle.fi/1-74221391"
	"https://areena.yle.fi/1-74221375"
	"https://areena.yle.fi/1-74221395"
	"https://areena.yle.fi/1-74221385"
	"https://areena.yle.fi/1-74221387"
	"https://areena.yle.fi/1-74221393"
	"https://areena.yle.fi/1-74221381"
	"https://areena.yle.fi/1-74221389"
	"https://areena.yle.fi/1-74221379"
)

for EP in "${EPISODES[@]}"; do
	echo ">>> PROCESSING '$EP'"
	# JSON="$(cat "1-72429050" | grep -Eo '\{"props":.*\}')"
	JSON="$(curl -s "$EP" | grep -Eo '\{"props":.*\}')"
	DOWNLOAD_URL="$(echo $JSON | jq --raw-output '.props.pageProps.view.header.controls[] | select(.title=="Lataa tiedosto") | .destination.uri')"
	TITLE_STRING="$(echo $JSON | jq --raw-output '.props.pageProps.meta.title')"

	# Parse episode number, title and podcast name from string like:
	#   `K1, J1: Blue Whale – Tappava somehaaste | Varjojen verkko`
	# using "parameter expansion"
	PNAME="$(echo "${TITLE_STRING##*|}" | xargs)"       # -> 'Varjojen verkko' (xargs trims space!)
	SE_EP="$(echo "${TITLE_STRING%%:*}" | tr -d ', ')"  # -> 'K1J1'
	TITLE="$(echo "${TITLE_STRING#*:}")"                # -> ' Blue Whale – Tappava somehaaste | Varjojen verkko'
	TITLE="$(echo "${TITLE%%|*}" | xargs)"              # -> 'Blue Whale – Tappava somehaaste'

	FILENAME="$PNAME $SE_EP - ${TITLE}.mp3"
	echo "- Download URL:  '$DOWNLOAD_URL'"
	echo "- Season&number: '$SE_EP'"
	echo "- Episode title: '$TITLE'"
	wget "$DOWNLOAD_URL" -O "$FILENAME"
	echo "==> Downloaded $(du -h "$FILENAME")"
done

