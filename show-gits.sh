#!/usr/bin/env bash

_script_name=$(basename -s .sh "$0")

# Same as set -euE -o pipefail
#set -o errexit
set -o nounset
set -o errtrace
#set -o pipefail
IFS=$'\n\t'


shopt -s globstar
shopt -s dotglob
shopt -s extglob

#-----------------------------------
#//Usage: show-gits [ {-d|[--]d[ebug]} ] [ {-f|[--]f[ull]} | {-h|[--]h[elp]} | {-l|[--]l[ist]} | {-s|[--]s[tatus]} | {-u|[--]upd[ate]} | {-U|[--]upg[rade]} ]
#//Description: Show the git repositories in your ${HOME} folder
#//Examples: show-gits -u; show-gits --update; show-gits upd
#//Options:
#//	-d [--]d[ebug]	  Enable debug mode
#//	-f [--]f[ull]	  Show full report of the repos
#//	-h [--]h[elp]	  Display this help message
#//	-l [--]l[ist]	  List the repos (without status)
#//	-s [--]s[tatus]	  Get the short status of the repos
#//	-u [--]upd[ate]	  Update the repos from remote
#//	-U [--]upg[rade]  Upgrade the repos from remote (git pull)

# Created: 2018-03-22
# Tristan M. Chase <tristan.m.chase@gmail.com>

# Depends on:
#  git

#-----------------------------------
# TODO Section (see ~/devel/conventional-commits/TODO for details)
# - [x] feat: add warning if sourced files are missing (feat-warning)
# - [x] feat: add upgrade repos function (feat-upgrade-repos)
# - [ ] refactor: rewrite git search (refactor-git-search)
# - [ ] refactor: replace _dirfile tempfile with array (refactor-array)
# - [x] refactor: refactor options (refactor-options)
# - [x] refactor: remove runtime (refactor-runtime)
# - [ ] feat: add __chooser__ (feat-chooser)
# - [ ] perf: [flesh this out: use coproc?] (perf-?)
# - [ ] refactor: rewrite options using getopt (refactor-options-getopt)

#-----------------------------------
# License Section

# Put license here

#-----------------------------------

# Initialize variables
#_temp="file.$$"
# TODO Use array only? (refactor-array)
_dirfile="${HOME}/tmp/show-gits.$$.tempfile" && touch "${_dirfile}"

# List of temp files to clean up on exit (put last)
_tempfiles=("${_dirfile}")

## Put main script here
function __main_script__ {
	:
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
function __git_ps1__ {
	__git_ps1 2>/dev/null
}

function __git_prompt__ {
	if [[ "$(printf "%b\n" "$(__git_ps1__)" | grep '[\*\+%<>\$]')" ]]; then
		_git_prompt_color="${bold_orange}"
	else
		_git_prompt_color="${BCYN}"
	fi

	printf "$(__git_ps1__)"
}

# Find the git repos in the ${HOME} directory (but exclude ~/.cache/)
function __git_search__ {
# TODO Refactor this (look to pathfinder) (refactor-git-search)
	printf "%b\n" ${HOME}/**/.git | sed 's/\/\.git//g' > "${_dirfile}"
	printf "%b\n" ${HOME}/.*/**/.git | grep -Ev '/\.(\.|cache)?/' | sed 's/\/\.git//g' >> "${_dirfile}"
}

# Get a list of the repos with the short status (default)
function __get_list_short__ {
	__git_search__
	for _dir in $(cat "${_dirfile}"); do
		cd "${_dir}"
		printf ""${bold_blue:-}"%s"${_git_prompt_color:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt__)"
		git -C "${_dir}" status -s
		#__find_trailing_whitespace_l__
	done
}

# Show the repos (-l|--list)
function __show_repos__ {
	__git_search__
	for _dir in $(cat "${_dirfile}"); do
		printf ""${bold_blue:-}"%s\n"${reset:-}"" "${_dir}"
	done
}

# Update the repos from remote (-u|--update)
#function __fetch_remotes__ {
function __update_repos__ {
	__git_search__
	for _dir in $(cat "${_dirfile}"); do
		printf "%b\n" "${_dir}"
		git -C "${_dir}" remote update
	done
}

# Get the full status of the repos (-f|--full)
function __get_full_status__ {
	__git_search__
	for _dir in $(cat "${_dirfile}"); do
		cd "${_dir}"
		printf ""${bold_blue:-}"%s"${_git_prompt_color:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt__)"
		git -C "${_dir}" status
		#__find_trailing_whitespace_l__
		printf "%b\n" ""
	done
}

# Get the short status of the repos (-s|--status)
function __get_short_status__ {
	__git_search__
	for _dir in $(cat "${_dirfile}"); do
		cd "${_dir}"
		if [[ "$(printf "%b\n" "$(__git_ps1__)" | grep '[\*\+%<>\$]')" ]]; then
			printf ""${bold_blue:-}"%s"${_git_prompt_color:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt__)"
			git -C "${_dir}" status -s
			#__find_trailing_whitespace_l__
		fi
	done
}

# Upgrade the repos from remote (-U|--upgrade)
function __upgrade_repos__ {
	# Update the repos from remote
	__update_repos__ #__fetch_remotes__
	# Find repos that can be upgraded via git pull
	_upgrade_list=(
	       	$(for _dir in $(cat "${_dirfile}"); do
			cd "${_dir}"
			if [[ "$(printf "%b\n" "$(__git_ps1__)" | grep '[<]')" ]]; then
				printf "%s\n" "${_dir}"
			fi
		done)
	)

	if [[ -z "${_upgrade_list[@]}" ]]; then
		printf "%b\n" ""${_script_name}": Repos are up to date."
		exit 0
	fi

	_file_count="${#_upgrade_list[@]}"
	if [[ "${_file_count}" -gt 1 ]]; then
		_file_noun="repos"
		_file_obj="them"
	else
		_file_noun="repo"
		_file_obj="it"
	fi

	# Present list of candidates for upgrade
	printf "%b\n"
	printf "%b\n" "The following "${_file_noun}" can be upgraded (git pull):"
	printf "  %s\n" "${_upgrade_list[@]}"
	printf "%b" "Would you like to upgrade "${_file_obj}" (y/N)? "
	read _upgrade_yN

	# Allow user to choose one, many, or all from the list
	# TODO Add chooser here (feat-chooser)

	# Upgrade repos
	if [[ "${_upgrade_yN}" =~ (y|Y) ]]; then
		for _repo in "${_upgrade_list[@]}"; do
			cd "${_repo}"
			printf "%b\n" "Upgrading ${_repo}"
			git pull
			printf "%b\n"
		done
	fi
	exit 0

}

function __local_cleanup__ {
	:
}

# Source helper functions
for _helper_file in functions colors git-prompt; do
	if [[ ! -e ${HOME}/."${_helper_file}".sh ]]; then
		printf "%b\n" "Downloading missing script file "${_helper_file}".sh..."
		sleep 1
		wget -nv -P ${HOME} https://raw.githubusercontent.com/tristanchase/dotfiles/main/"${_helper_file}".sh
		mv ${HOME}/"${_helper_file}".sh ${HOME}/."${_helper_file}".sh
	fi
done

source ${HOME}/.functions.sh
source ${HOME}/.git-prompt.sh

# Get some basic options
# TODO Make this more robust (use getopt? I kinda like the vim-like style) (refactor-options-getopt)
# TODO Refactor this (refactor-options)
case "${1:-}" in
	(-d|?(--)d?(e?(b?(u?(g))))) __debugger__ ;;
	(-h|?(--)h?(e?(l?(p)))) __usage__ ;;
	(-u|?(--)upd?(a?(t?(e)))) __update_repos__ ;; #__fetch_remotes__ ;;
	(-s|?(--)s?(t?(a?(t?(u?(s)))))) __get_short_status__ ;;
	(-l|?(--)l?(i?(s?(t)))) __show_repos__ | more -e ;;
	(-f|?(--)f?(u?(l?(l))))  __get_full_status__ | less -RFM +Gg ;;
	(-U|?(--)upg?(r?(a?(d?(e))))) __upgrade_repos__ ;;
	('') __get_list_short__ | more -e;; # Default behavio[u]r
	(*) printf "%b\n" "Option \""${1:-}"\" not recognized." ; __usage__ ;;
esac

# Main Script Wrapper
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
	trap __traperr__ ERR
	trap __ctrl_c__ INT
	trap __cleanup__ EXIT

	__main_script__


fi

exit 0
