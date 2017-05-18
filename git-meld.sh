#!/bin/bash
# Script that makes it possible to use 'Meld' as git diff-tool. To use, add this into user '.gitconfig' file:
#   [diff]
#   external = git-meld
#
# You can also set this global setting instead of modifying '.gitconfig':
#   $ git config --global diff.external git-meld
#
# Unset with these commands:
#   $ git config --global --unset meld
#   $ git config --global --unset diff.external (needed?)
#
# Taken from:
#   http://blog.deadlypenguin.com/blog/2011/05/03/using-meld-with-git-diff/
#
# NOTE:
# Git difftool knows meld and many other similar tools. Instead of this script, you can simply run:
#   $ git difftool <filename>
# Set default and disable prompt:
#   $ git config --global diff.tool meld
#   $ git config --global difftool.prompt false
#
/usr/bin/meld "$2" "$5"
