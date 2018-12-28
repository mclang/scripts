#!/bin/bash
#
# https://www.reddit.com/r/SteamPlay/comments/aa62kz/lego_lord_of_the_rings_wont_start/ecpeocn
#

# This is the APP ID of Lego Lord of the Rings
APPID=214510

export PROTON="Proton 3.16"
export STEAMLIB="/media/steam-lib"
export WINEPREFIX="${STEAMLIB}/steamapps/compatdata/${APPID}/pfx/"
export WINE="${STEAMLIB}/steamapps/common/${PROTON}/dist/bin/wine"

echo ""
echo "STEAM PLAY GAME INFORMATION"
echo "- Steam play (proton) version: '$PROTON'"
echo "- Steam APP ID:                '$APPID'"

for ITEM in "$STEAMLIB" "$WINEPREFIX" "$WINE"; do
	if [[ ! -e "$ITEM" ]]; then
		echo "ERROR: '$ITEM' not found!"
		exit
	fi
done

echo ""
echo "INSTALLING 'directx9' using winetricks"
echo ""
winetricks directx9

echo ""
echo "ALL DONE"
echo ""

