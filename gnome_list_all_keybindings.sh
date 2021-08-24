#!/bin/bash
# Finds all keybindings in all schemas visible for Gnome `gsettings`.
# Prints the hotkey/keybinding BEFORE the action and SORTS the output
# so that finding duplicates is easier.
#
# Longest `gsettings` example line I found was:
# ['<Super><Shift>Page_Down', '<Super><Shift><Alt>Right', '<Control><Shift><Alt>Right'] : org.gnome.desktop.wm.keybindings move-to-workspace-right
#
# NOTE: Not all duplicate keyboard shortcuts overlap though!
#
# Keybinding can be cleared with
# ```
# $ gsettings set org.gnome.shell.keybindings switch-to-application-1 []
# ```
#
set -e
set -u

# Finds ONLY the keybindings Gnome has:
# for SCHEMA in $(gsettings list-schemas | grep 'keybindings'); do
# 	for KEY in $(gsettings list-keys "${SCHEMA}"); do
# 		echo "$(gsettings get ${SCHEMA} ${KEY}): ${KEY}"
# 	done
# done | grep -v '@as \[\]' | sort

# Finds BOTH Gnome AND extension shortcuts
gsettings list-recursively |
grep -E "keybindings|hotkey" |
awk '{
	SCHEMA  = $1
	ACTION  = $2
	$1=$2=""
	BINDINGS = $0
	sub(/^[ \t\r\n]+/, "", BINDINGS)
	if (BINDINGS ~ /^\[[^\]]+\]/) {
		printf "%-30s %-45s %s\n", BINDINGS, SCHEMA, ACTION
	}
}' | sort # | uniq -D --check-chars 30


