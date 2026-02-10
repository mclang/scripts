#!/bin/bash
#
# Updates directory inodes so that they are in alphabetical order also in raw file tree.
#
set -ueo pipefail

echo "### ORIGINAL DIRECTORY INODE ORDER (as per 'find') ###"
find . -maxdepth 1 -type d -print
echo ""


echo "==> Fixing directory 'inode' order..."
mkdir -p "temp"
ls -d */ | sort | while IFS= read -r DIR; do
    [[ "$DIR" == "temp/" ]] && continue
    echo "- '$DIR'"
    mv "$DIR" temp/
done
mv temp/* .
rmdir "temp"
echo ""

echo "### NEW DIRECTORY INODE ORDER (as per 'find') ###"
find . -maxdepth 1 -type d -print

