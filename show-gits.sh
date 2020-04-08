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

# Find the git repos in the $HOME directory
find ~ -type d -name ".git" 2>/dev/null | xargs -n 1 dirname | sort > $dirfile

# Show the repos
show_repos(){
	cat $dirfile
}

# Update the repos from remote
fetch_remotes(){
	for f in `cat $dirfile`; do
		echo $f;
		cd $f;
		git remote update
	done
}

# Get the status of the repos
get_status() {
	for f in `cat $dirfile`; do
		cd $f;
		if [[ -n "$(git status -s)" ]]; then
			echo $f
			git status -s;
		fi
	done
	echo ""
}

# Search for conflicted files
get_conflicted() {
	conflicts=0

	for g in `cat $dirfile`; do
		if [[ -n `find $g -iname "*conflicted*" 2>/dev/null` ]]; then
			conflicts=1
		fi
	done

	if [ $conflicts -eq 1 ]; then
		echo "These directories contain conflicted files:"
		for h in `cat $dirfile`; do
			if [[ -n `find $h -iname "*conflicted*" 2>/dev/null` ]]; then
				find $h -iname "*conflicted*" 2>/dev/null | xargs -n 1 dirname
			fi
		done
	else
		echo "No conflicted files found in your git directories."
	fi
}

# Main
if [[ "$1" =~ (-u|--update) ]]; then
	fetch_remotes
elif [[ "$1" =~ (-s|--status) ]]; then
	get_status
	get_conflicted
else
	show_repos
fi

# Return to the starting directory
cd $startdir

exit 0

# TODO
# * Add boilerplate
# * Edit variable names to be more conformant
# * Edit function names to be more conformant
# * Modify command substitution to "$(this_style)"
# * Clean up stray ;'s
# * Make options more robust with getopt
