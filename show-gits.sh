#!/bin/bash
#
# show-gits.sh
#
# Tristan M. Chase 2018-03-22
#

# Create temp file for output of find
_dirfile="${HOME}"/tmp/show-gits.$$
touch ${_dirfile}

# Remove temp file on exit
trap cleanup EXIT

function cleanup() {
	rm ${_dirfile}
}


# Save current directory
_startdir="$(pwd)"

# Find the git repos in the ${HOME} directory
find ~ -type d -name ".git" 2>/dev/null | xargs -n 1 dirname | sort > ${_dirfile}

# Find files with trailing whitespace
function find_trailing_whitespace(){
	if [[ -n "$(grep -n '\s$' 2>/dev/null *)" ]]; then
		echo ">>>These files have trailing whitespace:"
		grep -n '\s$' 2>/dev/null *
	fi
}

# Show the repos (-l|--list)
function show_repos(){
	cat ${_dirfile}
}

# Update the repos from remote (-u|--update)
function fetch_remotes(){
	for _dir in $(cat ${_dirfile}); do
		echo ${_dir}
		cd ${_dir}
		git remote update
	done
}

function get_full_status(){
	for _dir in $(cat ${_dirfile}); do
		echo ${_dir}
		cd ${_dir}
		git status
		find_trailing_whitespace
		echo ""
	done
}

# Get the short status of the repos (-s|--status)
function get_short_status() {
	for _dir in $(cat ${_dirfile}); do
		cd ${_dir}
		if [[ -n "$(git status -s)" ]]; then
			echo ${_dir}
			git status -s
			find_trailing_whitespace
		fi
	done
}

if [[ "${1}" =~ (-u|--update) ]]; then
	fetch_remotes
elif [[ "${1}" =~ (-s|--status) ]]; then
	get_short_status
elif [[ "${1}" =~ (-l|--list) ]]; then
	show_repos
else
	get_full_status
fi

# Return to the starting directory
cd ${_startdir}

exit 0

# TODO
# * Add boilerplate
# * Make options more robust with getopt
# * Update description and options
