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


function update_repo() {
	if [[ -z "$1" || ! -d "$1" ]]; then
		print_w "Directory '$1' does not exist"
		return 0
	fi
	cd "$1"

	# Check if project has submodules and update them
	if [[ -e ".gitmodules" ]]; then
		update_submodules
	fi

	# NOTES:
	# - First check if this repo is for migrating from svn using Ruby 'svn2git' gem
	# - Using 'rebase' moves **local** commits into the end of the **fetched** remote commits.
	# - Using 'preserve' preserves local merges, i.e they are not flattened during rebase.
	if [[ -e ".git/svn/.metadata" ]]; then
		echo "==> Using 'svn2git' to get commits from old subversion repo..."
		svn2git --metadata --rebase --username mclang --password zaDam3!
		git pull --rebase
		# sometimes needed: git rebase origin/master
		CMD="git push --all"
	elif git status -uno | grep -q "modified"; then
		print_w "Directory '$1' has local modifications! => Using normal pull without rebase"
		CMD='git pull --no-rebase'
	else
		CMD='git pull --rebase=preserve'
	fi
	$CMD
	git log -2 --pretty="%Cred%h %Cgreen%ai %Cblue%<(10,trunc)%cn %Creset%s"
}


# Check that GIT SSH key is loaded (not bullet proof though!)
# Try to load first found git related key if possible.
if ! ssh-add -l | grep -iq 'git'; then
	if (( $(pgrep -cu $UID ssh-agent) == 0 )); then
		print_w "SSH agent is not running - cannot load Git SSH key"
		echo "==> Load agent and Git SSH key manually"
		exit
	fi
	GITKEY=$(find $HOME/.ssh -type f -regex ".*git.*" -not -name "*.pub")
	if [[ -z "$GITKEY" ]]; then
		print_w "Could not locate Git SSH key file"
		echo "==> Load agent and Git SSH key manually"
		exit
	fi
	echo -e "\n###  SSH key needed for Git repo update  ###\n"
	ssh-add "$GITKEY"
	if ! ssh-add -l | grep -iq 'git'; then
		print_w "Loading Git SSH key failed"
		echo "==> Load agent and Git SSH key manually"
		exit
	fi
fi


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
	update_repo "$PROJECTDIR"
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
	update_repo "$DIR"
done

