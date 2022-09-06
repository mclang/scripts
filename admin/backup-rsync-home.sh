#!/bin/bash
# Backups files in user HOME into the directory given as first parameter.
# Add '--dry-run' parameter for testing changes, and make **sure** the
# destination drive is mounted properly if using external device.
#
# Updated: 15.03.2021
#
set -u
set -e

EXCLUDES="backup-rsync-home_excludes.txt"
LOGFILE="backup-rsync-home_$(date +'%F-%H%M%S').log"
BACKUP_OPTS=(
#	"--dry-run"
	"--hard-links"
#	"--list-only"
	"--modify-window=5"
	"--progress"
#	"--delete-after"
#	"--delete-excluded"
#	"--prune-empty-dirs"
	"--exclude=${LOGFILE%_*}_*.log"
	"--exclude-from=${EXCLUDES}"
)

# IMPORTANT: Using '/' in the end means that the CONTENTS are synched into the destination, not the directory itself!
SRC_DIR="${HOME}/"
DST_DIR="$1"

if [[ ! -f "$EXCLUDES" ]]; then
	echo "ERROR: File '$EXCLUDES' does not exist!"
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

echo "###  STARTING DIRECTORY SYNC  ###" | tee -a "$LOGFILE"
echo "DATE:         $(date +'%F %T %z')" | tee -a "$LOGFILE"
echo "SOURCE:      '$SRC_DIR'"           | tee -a "$LOGFILE"
echo "DESTINATION: '$DST_DIR'"           | tee -a "$LOGFILE"
echo "LOG FILE:    '$LOGFILE'"           | tee -a "$LOGFILE"
echo "BACKUP OPTS: '${BACKUP_OPTS[@]}'"  | tee -a "$LOGFILE"
echo ""                                  | tee -a "$LOGFILE"

# Run `rsync` backup while outputting progress also into the given log file:
rsync -ah "${BACKUP_OPTS[@]}" "$SRC_DIR" "$DST_DIR" | tee -a "$LOGFILE"

# Copy also the log file after `rsync` has finished
rsync -ah "${LOGFILE}" "${DST_DIR}/${LOGFILE}"
