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
    if [[ ! -e "$GITDIR/index" ]]; then
        echo -en "\n\nWARNING: Not a GIT project: '$PROJECTDIR'\n\n"
        continue
    fi
    echo -e "\n==> Updating '$PROJECTDIR'..."
    cd "$PROJECTDIR"
    # Using 'rebase' moves local commits into the end of the fetched commits.
    # Using 'preserver' preserver local merges, i.e they are not flattened during rebase.
    git pull --rebase=preserve
    git log -1
    #if [[ -e ".wakatime-project" ]]; then
    #    git add -f .wakatime-project
    #    if `git status | grep -q "new file"`; then
    #        git commit -a -m "Added wakatime project file for optional time tracking"
    #        git push
    #    fi
    #fi
done
shopt -u globstar

