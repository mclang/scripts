#!/bin/bash
# Uses `dd` to read sectors from the disk from first bad one until good one is found.
# Find bad sectors from dmesg or journal with something like this:
#   $ journalctl -b | grep 'print_req_error' | awk '{print $NF-1}' | sort | uniq
#
# Read and Write commands taken from:
#   http://www.thelinuxdaily.com/2010/03/write-to-or-read-from-a-given-sector-using-dd/
#
# Updated: 21.03.2018
#

# Cannot set these b/c script would EXIT at first 'dd' error
#set -e
#set -u

DRIVE='/dev/sdd'
FIRST_BAD_SECTOR='770711267'
MAX_SECTORS_TO_CHECK=2000
NEXT_SECTOR="$FIRST_BAD_SECTOR"
LAST_SECTOR=$((FIRST_BAD_SECTOR+MAX_SECTORS_TO_CHECK))
BAD_SECTORS=()

echo ""
echo "###  FINDING CONSECUTIVE BAD SECTORS WITH 'DD'  ###"
echo "==> drive:       '$DRIVE'"
echo "==> max sectors: $MAX_SECTORS_TO_CHECK"
echo "==> start:       $NEXT_SECTOR"
echo "==> last:        $LAST_SECTOR"
echo ""

if (( $EUID != 0 )); then
	echo -e "\nTHIS SCRIPT NEEDS TO BE RUN AS 'roor' OR WITH 'sudo'!\n"
	exit 1
fi


while (( $NEXT_SECTOR < $LAST_SECTOR )); do
	echo "READING SECTOR '$NEXT_SECTOR'"
	dd if=${DRIVE} of=/dev/null skip=${NEXT_SECTOR} count=1 bs=512 > /dev/null 2>&1
	if (( $? > 0 )); then
		echo "==> BAD SECTOR"
		BAD_SECTORS+=("$NEXT_SECTOR")
	else
		echo "==> GOOD"
		break
	fi
	((NEXT_SECTOR++))
done

if (( $NEXT_SECTOR == $LAST_SECTOR )); then
	echo -e "\nSECTOR LIMIT REACHED!\n"
fi


# This is DANGEROUS - and MIGHT make things WORSE!!!
for BADSEC in "${BAD_SECTORS[@]}"; do
	echo "WRITING INTO SECTOR '$BADSEC'..."
	echo "dd if=/dev/urandom of=${DRIVE} seek=${BADSEC} count=1 bs=512 > /dev/null 2>&1"
	if (( $? > 0 )); then
		echo "==> WRITING FAILED"
	else
		echo "==> WRITING SUCCEEDED"
	fi
done

