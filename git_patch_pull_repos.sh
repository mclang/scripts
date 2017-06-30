#!/bin/bash
# Updates all git repositories that are found under PROJECTS directory.
# Notes:
# - SSH keys MUST be loaded beforehand
# - If using with cron, the SSH key must NOT have password
#
set -u
set -e

PROJECTS="/home/mclang/Projects"


function print_w() {
	echo -e "!!! $1"
}


function update_submodules() {
	# TODO:
	# 1. save current directory
	# 2. cd into each submodule directory
	# 3. check that the module IS NOT "HEAD detached at xxx" -> ERROR if it is
	# 4. update submodule
	git submodule update --remote --rebase
}


function git_pull() {
	if [[ -z "$1" || ! -d "$1" ]]; then
		print_w "Directory '$1' does not exist"
		return 0
	fi
	cd "$1"

	# Check if project has submodules and update them
	if [[ -e ".gitmodules" ]]; then
		update_submodules
	fi

	# Using 'rebase' moves **local** commits into the end of the **fetched** commits.
	# Using 'preserve' preserver local merges, i.e they are not flattened during rebase.
	if git status -uno | grep -q "modified"; then
		print_w "Directory '$1' has local modifications! => Using normal pull without rebase"
		REBASE='--no-rebase'
	else
		REBASE='--rebase=preserve'
	fi
	git pull $REBASE
	git log -2 --pretty="%Cred%h %Cgreen%ai %Cblue%<(10,trunc)%cn %Creset%s"
}


# Make sure globstar is enabled for searching git repositories under PROJECTS directory
shopt -s globstar

echo -e "\n\n###  UPDATING GIT REPOSITORIES UNDER '$PROJECTS'  ###"
for GITDIR in "$PROJECTS"/*/.git; do
	PROJECTDIR=$(dirname "$GITDIR")
	echo -e "\n==> Updating '$PROJECTDIR' ..."

	# Normal glob is enough to check what directories to skip
	if [[ "$PROJECTDIR" == *!git* ]]; then
		print_w "marked to be skipped (has '!git' in path name)"
		continue
	fi
	if [[ ! -e "$GITDIR/index" ]]; then
		print_w "This seems NOT to be a git repository"
		continue
	fi
	git_pull "$PROJECTDIR"
done
shopt -u globstar


# Pull also these git repositories located outside of PROJECTS directory:
declare -A GITREPOS=(
	["$HOME/.dotconfig"]='User dotconfig'
	["$HOME/bin"]='User bin directory'
)
echo -e "\n\n###  UPDATING OTHER GIT REPOSITORIES  ###"
for DIR in "${!GITREPOS[@]}"; do
	echo -e "\n==> Updating '${GITREPOS[$DIR]}' ..."
	git_pull "$DIR"
done

