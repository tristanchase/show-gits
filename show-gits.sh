#!/usr/bin/env bash

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
# TODO Section
# * Add warning if sourced files are missing
# * Replace old color variables with new ones
# * Replace _dirfile tempfile with array

# DONE
# + Options not working; change layout

#-----------------------------------
# License Section

# Put license here

#-----------------------------------

# Initialize variables
#_temp="file.$$"

# List of temp files to clean up on exit (put last)
#_tempfiles=("${_temp}")

# Put main script here
function __main_script__ {
	__globstar__

	# Create temp file for output of find
	# TODO Use array only?
	_dirfile=""${HOME}"/tmp/show-gits.$$.tempfile"
	touch "${_dirfile}"

	# Save current directory
	_startdir="$(pwd)"

	# Find the git repos in the "${HOME}" directory (but exclude ~/.cache/)
	printf "%b\n" "${HOME}"/**/.git | sed 's/\/\.git//g' > "${_dirfile}"
	printf '%b\n' "${HOME}"/.*/**/.git | grep -Ev '/\.(\.|cache)?/' | sed 's/\/\.git//g' >> "${_dirfile}"


	# Runtime
	if [[ "${_fetch_remotes_yN:-}" = "y" ]];then
		__fetch_remotes__
	elif [[ "${_get_short_status_yN:-}" = "y" ]];then
		__get_short_status__
	elif [[ "${_show_repos__yN:-}" = "y" ]];then
		__show_repos__ | more
	elif [[ "${_get_full_status__yN:-}" = "y" ]];then
		__get_full_status__ | more
	else
		__get_list_short__ | more
	fi
	# End runtime

	# Return to the starting directory
	cd "${_startdir}"

} #end __main_script__

# Local functions

# Find files with trailing whitespace (but not .pdf's or other binary files)
function __find_trailing_whitespace_l__ {
	if [[ -n "$(grep --files-with-matches --binary-files=without-match '\s$' 2>/dev/null "${_dir}"/*)" ]]; then
		printf "${WHT:-}${CYNB:-}%s\n" ">>>These files have trailing whitespace:"
		grep --files-with-matches --binary-files=without-match '\s$' 2>/dev/null "${_dir}"/* | xargs realpath
		printf ""${reset:-}"%b\n"
	fi
}

# Show git status à la git-prompt.sh
function __git_prompt__ {
	if [[ -e "${HOME}"/.git-prompt.sh ]]; then
		source ~/.git-prompt.sh
		__git_ps1 2>/dev/null
	fi
}

# Get a list of the repos with the short status (default)
function __get_list_short__ {
	for _dir in $(cat "${_dirfile}"); do
		cd "${_dir}"
		printf ""${BBLU:-}"%s"${BCYN:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt__)"
		git -C "${_dir}" status -s
		__find_trailing_whitespace_l__
	done
}

# Show the repos (-l|--list)
function __show_repos__ {
	#cat "${_dirfile}"
	printf ""${BBLU:-}"%s\n"${reset:-}"" "$(cat "${_dirfile}")"
}

# Update the repos from remote (-u|--update)
function __fetch_remotes__ {
	for _dir in $(cat "${_dirfile}"); do
		printf "%b\n" "${_dir}"
		git -C "${_dir}" remote update
	done
}

# Get the full status of the repos (-f|--full)
function __get_full_status__ {
	for _dir in $(cat "${_dirfile}"); do
		#printf "%b\n" "${_dir}"
		cd "${_dir}"
		#printf "%b\n" ""${_dir}"$(__git_prompt__)"
		printf ""${BBLU:-}"%s"${BCYN:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt__)"
		git -C "${_dir}" status
		__find_trailing_whitespace_l__
		printf "%b\n" ""
	done
}

# Get the short status of the repos (-s|--status)
function __get_short_status__ {
	for _dir in $(cat "${_dirfile}"); do
		if [[ -n "$(git -C "${_dir}" status -s)" ]]; then
			#printf "%b\n" "${_dir}"
			cd "${_dir}"
			#printf "%b\n" ""${_dir}"$(__git_prompt__)"
			printf ""${BBLU:-}"%s"${BCYN:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt__)"
			git -C "${_dir}" status -s
			__find_trailing_whitespace_l__
		fi
	done
}

function __local_cleanup__ {
	:
}

# Source helper functions
if [[ -e ~/.functions.sh ]]; then
	source ~/.functions.sh
fi

# Get some basic options
# TODO Make this more robust
if [[ "${1:-}" =~ (-d|--debug) ]]; then
	__debugger__
elif [[ "${1:-}" =~ (-h|--help) ]]; then
	__usage__
elif [[ "${1:-}" =~ (-u|--update) ]]; then
	_fetch_remotes_yN="y"
elif [[ "${1:-}" =~ (-s|--status) ]]; then
	_get_short_status_yN="y"
elif [[ "${1:-}" =~ (-l|--list) ]]; then
	_show_repos__yN="y"
elif [[ "${1:-}" =~ (-f|--full) ]]; then
	_get_full_status__yN="y"
fi

# Bash settings
# Same as set -euE -o pipefail
set -o errexit
set -o nounset
set -o errtrace
set -o pipefail
IFS=$'\n\t'

# Main Script Wrapper
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
	trap __traperr__ ERR
	trap __ctrl_c__ INT
	trap __cleanup__ EXIT

	__main_script__


fi

exit 0
