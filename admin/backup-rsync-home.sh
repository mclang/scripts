#!/bin/bash
# Copies user HOME directory into the destination directory given as
# the first and single parameter.
#
# Uncomment `--dry-run` parameter for testing changes, and make **sure**
# the destination drive is mounted properly when using external device.
#
set -euo pipefail
VERSION="2023-12-08"


# RSYNC PARAMETER NOTES:
# - As of 05.12.2023, `backup-rsync-home_excludes.txt` does NOT ignore `[!]` (b/c I WANT IT ALL).
# - Consider `--munge-links` to make links safer?
# - Add `-W` (`--whole-file`) when doing first sync of large dataset
# - Using `--inplace` reduces HDD trashing but might make files broken if transfer is stopped abruptly
BASEDIR=$(dirname "$(readlink -nf $0)")
EXCLUDE="${BASEDIR}/backup-rsync-home_excludes.txt"
LOGFILE="${BASEDIR}/backup-rsync-home_$(date +'%F-%H%M%S').log"
BACKUP_OPTS=(
	"-ahAXE"
#	"--dry-run"
	"--hard-links"
	"--links"
	"--safe-links"
#	"--list-only"
	"--modify-window=5"
	"--progress"
	"--info=stats2"
#	"--delete-after"
#	"--delete-excluded"     DO NOT ENABLE THIS - USE E.G `find <backup-dir> -mtime +356 -print` INSTEAD
#	"--prune-empty-dirs"
	"--update"
	"--inplace"
#	"--whole-file"
	"--exclude=backup-rsync-home_*.log"
	"--exclude-from=${EXCLUDE}"
)

# IMPORTANT:
# - Using '/' in the end of SRC means that the CONTENTS are synched into the DST, not the directory itself!
# - Destination is not `$1/$(basename $SRC_DIR) b/c that could result in one too deep directory structure.
SRC_DIR="${HOME}/"
DST_DIR="$1"

if [[ ! -f "$EXCLUDE" ]]; then
	echo "ERROR: File '$EXCLUDE' does not exist!"
	exit 1
fi
if [[ "$(basename $SRC_DIR)" != "$(basename $DST_DIR)" ]]; then
	echo "ERROR: Invalid destination directory!"
	echo "This script is for backing up user HOME directory, so both source and"
	echo "destination directories should have the same basename, i.e '$(basename $SRC_DIR)'"
	exit 1
fi
if [[ ! -d "$SRC_DIR" ]]; then
	echo "ERROR: Directory '$SRC_DIR' does not exist!"
	exit 1
fi
if [[ ! -d "$DST_DIR" ]]; then
	echo "ERROR: Directory '$DST_DIR' does not exist!"
	exit 1
fi

# Putting header info inside code block makes using `tee -a` nicer :)
{
	echo "###  STARTING HOME DIRECTORY SYNC  ###"
	echo "DATE:           $(date +'%F %T %z')"
	echo "SCRIPT VERSION: $VERSION"
	echo "SOURCE DIR:     '$SRC_DIR'"
	echo "DESTINATION:    '$DST_DIR'"
	echo "BACKUP OPTIONS:"
	printf "    %s\n" "${BACKUP_OPTS[@]}"
	echo "LOG FILE:       '$LOGFILE'"
	echo ""
}| tee -a "$LOGFILE"

# Run `rsync` backup while outputting progress also into the given log file:
rsync "${BACKUP_OPTS[@]}" "$SRC_DIR" "$DST_DIR" | tee -a "$LOGFILE"
echo ""

# Copy also the log file after `rsync` has finished
mv -v "${LOGFILE}" "${DST_DIR}/"

echo ""
echo "###  DONE  ###"
echo ""

