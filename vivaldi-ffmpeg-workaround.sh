#!/bin/bash
# Vivaldi and Opera cannot play some videos on Linux unless the ffmpeg library they use is replaced with proper one.
#
# Updated: 06.02.2018
#
set -e
set -u

FFMPEG_ZIP="https://github.com/iteufel/nwjs-ffmpeg-prebuilt/releases/download/0.28.0/0.28.0-linux-x64.zip"
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

