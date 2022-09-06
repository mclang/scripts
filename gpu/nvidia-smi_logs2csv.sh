#!/bin/bash
# Converts logs created with this `nvidia-smi` command:
# ```
# $ nvidia-smi dmon -s puc -d 1 -o DT | tee -a ~/Documents/Dell-XPS15-logs/nvidia-smi_(date +"%F").log
# ```
# Into proper CSV files WITHOUT unnecessary headers in the middle
#
# NOTE: Square brackets in `tr` command must be escaped!
# TODO: Remove unnecessary semicolon from the beginning of the line
set -e
set -u
shopt -s nullglob

for LOG in *.log; do
	CSV="$(basename $LOG .log).csv"
	if [[ -e "$CSV" ]]; then
		echo "Skipping '$LOG' b/c '$CSV' exists..."
		continue
	fi
	echo "Converting '$LOG' -> '$CSV'"
	head -n 2     "$LOG" | tr -s \[#\[:blank:\]\] ';' >  "$CSV"
	grep -Ev '^#' "$LOG" | tr -s \[#\[:blank:\]\] ';' >> "$CSV"
done

