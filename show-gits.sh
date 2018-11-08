#!/bin/bash
#
# show-gits.sh
#
# Tristan M. Chase 2018-03-22
#
# Shows where your various git repos are, the status of each, and any directories containing conflicted files.
#
# Original one-liner:
#find ~ -type d -name .git 2>/dev/null | xargs -n 1 dirname

# Create temp file for output of find
dirfile=/tmp/show-gits.$$
touch $dirfile

# Remove temp file on exit
trap cleanup EXIT

cleanup () {
	rm $dirfile
}

# Save current directory
startdir="`pwd`"

# Get the git repos and the status of each
find ~ -type d -name "*.git" 2>/dev/null | xargs -n 1 dirname | sort > $dirfile

for f in `cat $dirfile`; do
	echo $f; 
	cd $f;
	git status -s;
done

echo ""

# Search for conflicted files
if [[ -z `find ~ -name "*conflicted*" 2>/dev/null` ]]; then
	echo "No conflicted files found."
else
	echo "These directories contain conflicted files:"
	find ~ -name "*conflicted*" 2>/dev/null | xargs -n 1 dirname | sort | uniq
fi

# Return to the starting directory
cd $startdir

exit 0
