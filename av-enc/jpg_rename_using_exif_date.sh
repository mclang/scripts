#!/bin/bash
# Renames given 'jpg' files so that they start with EXIF Image Timestamp like so:
#   yyyy-mm-dd_<orig-name>
# Handles also files that do not have EXIF data if they are like
# 'IMG-20181128-WA0002.jpg', which come usually from WhatsApp.
#

# if there is NO matching files, don't try to process the GLOB as an actual file
shopt -s nullglob

FILES=( $@ )
COUNT=${#FILES[@]}


function RenameUsingEXIF()
{
	# Parse camera make and model:
	MAKE=$(exiv2 "$1" | grep -i 'Camera make'  | cut -d ':' -f 2 | tr -d \[:blank:\])
	MODL=$(exiv2 "$1" | grep -i 'Camera model' | cut -d ':' -f 2 | tr -d \[:blank:\])

	###  'exiv2' parameters  ###
	# Set tag information for jpg files but DO NOT touch RAW files b/c 'Offset of directory Sony1, entry 0x2001...'
	# -k  preserve file timestamp when updating eg. EXIF data
	# -t  set timestamp according to EXIF while renaming file
	# -T  set timestamp, do NOT rename file
	# -q  supresses some unimportant warnings, like 'Offset of directory Sony1, entry 0x2001...'
	exiv2 -k -q -M"set Exif.Image.Artist Maija Keinänen" "$1"
	exiv2 -k -q -M"set Exif.Image.Copyright Copyright © $(date +'%Y') Maija Keinänen" "$1"
	exiv2 -t -r"%Y-%m-%d_%H%M%S_${MAKE}-${MODL}" rename "$1"
}

function RenameUsingFilename()
{
	# Handles files like 'IMG-20181128-WA0002.jpg' that come from WhatsApp
	WAPPFILE=$(echo "$(basename "$1")" | grep -Eo 'IMG-[[:digit:]]{8}-WA[[:digit:]]{4}.jpg')
	if [[ -z "$WAPPFILE" ]]; then
		echo "==> Cannot parse date from '$1'!"
		return
	fi
	DATESTR=$(echo "$WAPPFILE" | grep -Eo '[[:digit:]]{8}')
	WAPPSTR=$(echo "$WAPPFILE" | grep -Eo 'WA[[:digit:]]{4}')
	EXIFDATE=$(date --date="$DATESTR" +"%Y:%m:%d")
	echo "==> '$WAPPFILE' --> '$EXIFDATE' ($WAPPSTR)"

	# Set 'Exif.Photo.DateTimeOriginal' that is the date when the photo was taken.
	# Do NOT set Artis/Copyright b/c the file has come from someone else!
	exiv2 -M"set Exif.Photo.DateTimeOriginal $EXIFDATE 00:00:00" "$1"

	# Rename according to EXIF timestamp, use 'WA[0-9]' as a tag without HMS b/c it is not known
	exiv2 -t -r"%Y-%m-%d_${WAPPSTR}" rename "$1"
}

function RenameUsingModTime()
{
	dt=$(date +"%F" -r "$1")
	echo "==> File '$1' is modified '$dt'"
}


# Check that 'exiv2' is installed
if ! hash exiv2 2>/dev/null; then
	echo -e "\nERROR: 'exiv2' is needed to rename photos!\n"
	return
fi

# bail out if no files found
if [[ $COUNT -eq 0 || ! -e "${FILES[0]}" ]]; then
	echo -e "\n!!! NO JPG FILES SPECIFIED !!!\n"
	exit 1
fi


echo ""
echo "Renaming $COUNT files using EXIF and/or filename data"
for FL in "${FILES[@]}"; do
	echo "Processing '$FL'"

	# Skip filenames that start like 'yyyy-mm-dd' i.e files that have been renamed already
	# NOTE: Pattern MUST be unquoted!
	if [[ "$(basename "$FL")" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
		echo "==> SKIPPIN: File seems to be renamed already!"
		continue
	fi

	# Check if file has EXIF information
	if exiv2 "$FL" 2>/dev/null | grep -q 'Image timestamp'; then
		echo "==> EXIF data found, using 'exiv2'"
		RenameUsingEXIF "$FL"
	else
		echo "==> EXIF data NOT found, using filename"
		RenameUsingFilename "$FL"
	fi
done
