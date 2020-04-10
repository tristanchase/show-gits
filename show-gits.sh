#!/usr/bin/env bash
set -euo pipefail
set -o errtrace
#set -x
IFS=$'\n\t'

#-----------------------------------

#/ Usage: show-gits [ {-h|--help} | {-l|--list} | {-u|--update} | {-s|--status} ]
#/ Description: Show the git repositories in your "${HOME}" folder
#/ Examples: show-gits --update, show-gits -l
#/ Options:
#/	 -h --help	Display this help message
#/	 -l --list	Show the repos
#/	 -u --update	Update the repos from remote
#/	 -s --status	Get the short status of the repos

# Created: 2018-03-22
# Tristan M. Chase <tristan.m.chase@gmail.com>

# Depends on:
#  git

#-----------------------------------
# Low-tech help option

function __usage() { grep '^#/' "${0}" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && __usage

#-----------------------------------
# Low-tech logging function

readonly LOG_FILE=""${HOME}"/tmp/$(basename "${0}").log"
function __info()    { echo "[INFO]    $*" | tee -a "${LOG_FILE}" >&2 ; }
function __warning() { echo "[WARNING] $*" | tee -a "${LOG_FILE}" >&2 ; }
function __error()   { echo "[ERROR]   $*" | tee -a "${LOG_FILE}" >&2 ; }
function __fatal()   { echo "[FATAL]   $*" | tee -a "${LOG_FILE}" >&2 ; exit 1 ; }

#-----------------------------------
# Trap functions

function __traperr() {
	__info "ERROR: ${FUNCNAME[1]}: ${BASH_COMMAND}: $?: ${BASH_SOURCE[1]}.$$ at line ${BASH_LINENO[0]}"
}

function __ctrl_c() {
	exit 2
}

function __cleanup() {
	rm ${_dirfile}

	case "$?" in
		0) # exit 0; success!
			#do nothing
			;;
		2) # exit 2; user termination
			__info ""$(basename $0).$$": script terminated by user."
			;;
		*) # any other exit number; indicates an error in the script
			#clean up stray files
			__fatal ""$(basename $0).$$": [error message here]"
			;;
	esac
}

#-----------------------------------
# Main Script Wrapper

if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
	trap __traperr ERR
	trap __ctrl_c INT
	trap __cleanup EXIT
#-----------------------------------
# Main Script goes here

# Create temp file for output of find
_dirfile="${HOME}"/tmp/show-gits.$$.tempfile
touch ${_dirfile}

# Save current directory
_startdir="$(pwd)"

# Find the git repos in the ${HOME} directory
find ~ -type d -name ".git" 2>/dev/null | xargs -n 1 dirname | sort > ${_dirfile}

# Find files with trailing whitespace (but not .pdf's or other binary files)
function __find_trailing_whitespace(){
	if [[ -n "$(grep --files-with-matches --binary-files=without-match '\s$' 2>/dev/null *)" ]]; then
		echo ">>>These files have trailing whitespace:"
		grep --binary-files=without-match '\s$' 2>/dev/null *
	fi
}

#   -l --list	Show the repos
function __show_repos(){
	cat ${_dirfile}
}

#   -u --update	Update the repos from remote
function __fetch_remotes(){
	for _dir in $(cat ${_dirfile}); do
		echo ${_dir}
		cd ${_dir}
		git remote update
	done
}

function __get_full_status(){
	for _dir in $(cat ${_dirfile}); do
		echo ${_dir}
		cd ${_dir}
		git status
		__find_trailing_whitespace
		echo ""
	done
}

#   -s --status	Get the short status of the repos
function __get_short_status() {
	for _dir in $(cat ${_dirfile}); do
		cd ${_dir}
		if [[ -n "$(git status -s)" ]]; then
			echo ${_dir}
			git status -s
			__find_trailing_whitespace
		fi
	done
}

# Runtime
if [[ "${1:-}" =~ (-u|--update) ]]; then
	__fetch_remotes
elif [[ "${1:-}" =~ (-s|--status) ]]; then
	__get_short_status
elif [[ "${1:-}" =~ (-l|--list) ]]; then
	__show_repos
elif [[ "${1:-}" =~ (-h|--help) ]]; then
	__usage
else
	__get_full_status
fi
# End runtime

# Return to the starting directory
cd ${_startdir}

# Main Script ends here
#-----------------------------------

fi

# End of Main Script Wrapper
#-----------------------------------

exit 0

# TODO
# * Make options more robust with getopt
