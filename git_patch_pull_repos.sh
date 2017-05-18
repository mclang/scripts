#!/bin/bash
# Updates all git repos that are found under PROJECTS directory.
# Notes:
# - SSH keys MUST be loaded beforehand
# - If using with cron, the SSH key must not have password
#
set -u
set -e

PROJECTS="/home/mclang/Projects"

# Make sure globstar is enabled
shopt -s globstar

# for GITDIR in "$PROJECTS"/**/.git; do
for GITDIR in "$PROJECTS"/*/.git; do
	PROJECTDIR=$(dirname "$GITDIR")

	# Normal glob is enough to check what directories to skip
	if [[ "$PROJECTDIR" == *!git* ]]; then
		echo -en "\n\nWARNING: Skipping project: '$PROJECTDIR'\n\n"
		continue
	fi

	if [[ "$PROJECTDIR" == "/home/mclang/Projects/GenerateDriveEvents" ]]; then
		continue
	fi
	if [[ ! -e "$GITDIR/index" ]]; then
		echo -en "\n\nWARNING: Not a GIT project: '$PROJECTDIR'\n\n"
		continue
	fi
	echo -e "\n==> Updating '$PROJECTDIR'..."
	cd "$PROJECTDIR"
	# Using 'rebase' moves local commits into the end of the fetched commits.
	# Using 'preserver' preserver local merges, i.e they are not flattened during rebase.
	git pull --rebase=preserve
	git log -1 --pretty="%Cred%h %Cgreen%ai %Cblue%<(10,trunc)%cn %Creset%s"
done
shopt -u globstar

exit

# Other git repositories:
echo -e "\n==> Updating 'User DotFiles'..."
cd "$HOME/.dotconfig"
git pull --rebase=preserve
git log -1 --pretty="%Cred%h %Cgreen%ai %Cblue%<(10,trunc)%cn %Creset%s"

