#!/bin/bash
# Vivaldi and Opera cannot play some videos on Linux unless the ffmpeg library they use is replaced with proper one.
#
# Updated: 04.05.2018
#
set -e
set -u

# Testing against '$1' directly does not work b/c of 'set -u'
if [[ -z "$@" ]]; then
	echo ""
	echo "USAGE:"
	echo "$ $(basename "$0") https://github.com/iteufel/nwjs-ffmpeg-prebuilt/releases/download/X.YY.Z/X.YY.Z-linux-x64.zip"
	echo ""
	exit 1
fi

FFMPEG_ZIP="$1"
FFMPEG_LIB="libffmpeg.so"
LIB_DIR="/usr/share/vivaldi-stable/lib"
TMP_DIR="/tmp/$(basename $0 '.sh')"

echo ""
echo "###  Running Vivaldi FFMPEG Workaround  ###"

echo "Creating temp directory '$TMP_DIR'..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"
echo "==> DONE"

echo "Downloading and unzipping ffmpeg release zip..."
echo "==> '$FFMPEG_ZIP'"
wget -q "$FFMPEG_ZIP"
unzip *.zip
echo "==> DONE"

echo "Making backup of original ffmpeg lib..."
if [[ -e "${LIB_DIR}/${FFMPEG_LIB}" ]]; then
	sudo mv -v "${LIB_DIR}/${FFMPEG_LIB}" "${LIB_DIR}/${FFMPEG_LIB}_$(date +'%F')"
	echo "==> DONE"
else
	echo "==> original does not exist!"
fi

echo "Copying workaround ffmpeg lib..."
sudo cp -v "${TMP_DIR}/${FFMPEG_LIB}" "${LIB_DIR}/"
echo "==> DONE"

echo ""
# Return into the original directory and delete the temp dir
cd -
rm -vrf "$TMP_DIR"

