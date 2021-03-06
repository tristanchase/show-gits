#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o errtrace
set -o pipefail

# Enable debug mode
if [[ "${1:-}" =~ (-d|--debug) ]]; then
	set -o verbose
	set -o xtrace
	# next 3 lines moved here (see NOTE below)
	#set -o errtrace
	#set -o pipefail
	#trap __traperr ERR
	exec > >(tee ""${HOME}"/tmp/$(basename "${0}")-debug.$$") 2>&1
	shift
fi

IFS=$'\n\t'

# Allow bash to use **/ to match directories and subdirectories
shopt -s globstar

#-----------------------------------

#//Usage: show-gits [ {-d|--debug} ] [ {-f|--full} {-h|--help} | {-l|--list} | {-u|--update} | {-s|--status} ]
#//Description: Show the git repositories in your "${HOME}" folder
#//Examples: show-gits --update; show-gits -l
#//Options:
#//	-d --debug	Enable debug mode
#//	-f --full	Show full report of the repos
#//	-h --help	Display this help message
#//	-l --list	Show the repos
#//	-s --status	Get the short status of the repos
#//	-u --update	Update the repos from remote

# Created: 2018-03-22
# Tristan M. Chase <tristan.m.chase@gmail.com>

# Depends on:
#  git

#-----------------------------------
# Low-tech help option

function __usage() { grep '^#//' "${0}" | cut -c4- ; exit 0 ; }
expr "$*" : ".*-h\|--help" > /dev/null && __usage

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
	__error "ERROR: ${FUNCNAME[1]}: ${BASH_COMMAND}: $?: ${BASH_SOURCE[1]}.$$ at line ${BASH_LINENO[0]}"
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

if [[ -e ~/.colors.sh ]]; then
	source ~/.colors.sh
fi

# Create temp file for output of find
# TODO Use array only?
_dirfile="${HOME}"/tmp/show-gits.$$.tempfile
touch ${_dirfile}

# Save current directory
_startdir="$(pwd)"

# Find the git repos in the ${HOME} directory (but exclude ~/.cache/)
printf "%b\n" ${HOME}/**/.git | sed 's/\/\.git//g' > ${_dirfile}
printf '%b\n' ${HOME}/.*/**/.git | grep -Ev '/\.(\.|cache)?/' | sed 's/\/\.git//g' >> ${_dirfile}

# Find files with trailing whitespace (but not .pdf's or other binary files)
function __find_trailing_whitespace(){
	if [[ -n "$(grep --files-with-matches --binary-files=without-match '\s$' 2>/dev/null "${_dir}"/*)" ]]; then
		printf "${WHT:-}${CYNB:-}%s\n" ">>>These files have trailing whitespace:"
		grep --files-with-matches --binary-files=without-match '\s$' 2>/dev/null "${_dir}"/* | xargs realpath
		printf ""${reset:-}"%b\n"
	fi
}

# Show git status à la git-prompt.sh
function __git_prompt {
	if [[ -e $HOME/.git-prompt.sh ]]; then
		source ~/.git-prompt.sh
		__git_ps1 2>/dev/null
	fi
}

# Get a list of the repos with the short status (default)
function __get_list_short(){
	for _dir in $(cat ${_dirfile}); do
		cd "${_dir}"
		printf ""${BBLU:-}"%s"${BCYN:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt)"
		git -C "${_dir}" status -s
		__find_trailing_whitespace
	done
}

# Show the repos (-l|--list)
function __show_repos(){
	#cat ${_dirfile}
	printf ""${BBLU:-}"%s\n"${reset:-}"" "$(cat ${_dirfile})"
}

# Update the repos from remote (-u|--update)
function __fetch_remotes(){
	for _dir in $(cat ${_dirfile}); do
		printf "%b\n" ${_dir}
		git -C "${_dir}" remote update
	done
}

# Get the full status of the repos (-f|--full)
function __get_full_status(){
	for _dir in $(cat ${_dirfile}); do
		#printf "%b\n" ${_dir}
		cd "${_dir}"
		#printf "%b\n" "${_dir}$(__git_prompt)"
		printf ""${BBLU:-}"%s"${BCYN:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt)"
		git -C "${_dir}" status
		__find_trailing_whitespace
		printf "%b\n" ""
	done
}

# Get the short status of the repos (-s|--status)
function __get_short_status() {
	for _dir in $(cat ${_dirfile}); do
		if [[ -n "$(git -C "${_dir}" status -s)" ]]; then
			#printf "%b\n" ${_dir}
			cd "${_dir}"
			#printf "%b\n" "${_dir}$(__git_prompt)"
			printf ""${BBLU:-}"%s"${BCYN:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt)"
			git -C "${_dir}" status -s
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
	__show_repos | more
elif [[ "${1:-}" =~ (-f|--full) ]]; then
	__get_full_status | more
else
	__get_list_short | more
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
