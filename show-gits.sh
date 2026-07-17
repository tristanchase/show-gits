#!/usr/bin/env bash

# Same as set -euE -o pipefail
#set -o errexit
#set -o nounset
#set -o errtrace
#set -o pipefail
IFS=$'\n\t'

shopt -s globstar
shopt -s dotglob
shopt -s extglob

_script_name=$(basename -s .sh "$0")

#-----------------------------------
function __show_help__ {
	cat << EOF
Usage: ${_script_name} [OPTIONS]

Description: Show the git repositories in your ${HOME} folder

Options:
  -d, [--]d[ebug]	Enable debug mode
  -f, [--]f[ull]	Show full report of the repos
  -h, [--]h[elp]	Display this help message
  -l, [--]l[ist]	List the repos (without status)
  -s, [--]s[tatus]	List the repos with short status
  -u, [--]upd[ate]	Update the repos from remote
  -U, [--]upg[rade]	Upgrade the repos from remote (git pull)

Examples:
  ${_script_name} -u
  ${_script_name} --update
  ${_script_name} upd
EOF

exit 2
}


# Created: 2018-03-22
# Tristan M. Chase <tristan.m.chase@gmail.com>

# Depends on:
#  git

#-----------------------------------
# TODO Section (see ~/devel/conventional-commits/TODO for details)
# - [x] feat: add warning if sourced files are missing (feat-warning)
# - [x] feat: add upgrade repos function (feat-upgrade-repos)
# - [x] refactor: refactor options (refactor-options)
# - [x] refactor: remove runtime (refactor-runtime)
# - [x] refactor: remove __find_trailing_whitespace__ (refactor-remove-ws)
# - [x] refactor: remove __find_trailing_whitespace_l__ (refactor-remove-ws)
# - [x] refactor: rewrite git search (refactor-git-search)
# - [x] refactor: replace _dirfile tempfile with array (refactor-array)
# - [x] perf: rewrite __update_repos__ (perf-update-repos)
# - [ ] feat: add __chooser__ (feat-chooser)
# - [ ] feat: add timestamp option (feat-timestamp)
# - [ ] refactor: rewrite options using getopt (refactor-options-getopt)

#-----------------------------------
# License Section

# Put license here

#-----------------------------------

# Initialize variables
_arg='.git'
_git_array=( $(printf "%b\n" $HOME/**/ | grep "${_arg}"/$ | xargs dirname ) )

# List of temp files to clean up on exit (put last)
#_tempfiles=("${_dirfile}")

## Put main script here
function __main_script__ {
	:
} #end __main_script__

# Local functions

# Show git status à la git-prompt.sh
function __git_ps1__ {
	__git_ps1 2>/dev/null
}

function __git_prompt__ {
	if [[ "$(printf "%b\n" "$(__git_ps1__)" | grep '[\*\+%<>\$]')" ]]; then
		_git_prompt_color="${bold_orange}"
	else
		_git_prompt_color="${bold_cyan}"
	fi

	printf "$(__git_ps1__)"
}

# Get a list of the repos with the short status (-s|--status)
function __full_list_short_status__ {
	for _dir in "${_git_array[@]}"; do
		printf "%b\n" "${_dir}"
		git -C "${_dir}" status -s
	done
}

# Show the repos (-l|--list)
function __list_repos__ {
	for _dir in "${_git_array[@]}"; do
		printf "%b\n" "${_dir}"
	done
}

# Update the repos from remote (-u|--update)
function __update_repos__ {
	printf "%b\n" $HOME/**/ | grep "${_arg}"/$ | xargs dirname \
	| xargs -P 16 -I {} sh -c ' git -C {} remote update > /dev/null && echo "{}...updated"'
}

# Get the full status of the repos (-f|--full)
function __full_list_full_status__ {
	for _dir in "${_git_array[@]}"; do
		printf "%b\n" "${_dir}"
		git -C "${_dir}" status
		printf "%b\n" ""
	done
}

# Get the short status of the repos (default)
function __short_list_short_status__ {
	for _dir in "${_git_array[@]}"; do
		cd "${_dir}"
		if [[ "$(printf "%b\n" "$(__git_ps1__)" | grep '[\*\+%<>\$]')" ]]; then
			printf "%b\n" "${_dir}"
			git -C "${_dir}" status -s
		fi
	done
}

# Upgrade the repos from remote (-U|--upgrade)
function __upgrade_repos__ {
	# Update the repos from remote
	__update_repos__ #__fetch_remotes__
	# Find repos that can be upgraded via git pull
	_upgrade_list=(
		$(for _dir in "${_git_array[@]}"; do
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
# refactor: rewrite options using getopt (refactor-options-getopt)
case "${1:-}" in
	(-d|?(--)d?(e?(b?(u?(g))))) __debugger__ ;;
	(-h|?(--)h?(e?(l?(p)))) __show_help__ ;;
	(-s|?(--)s?(t?(a?(t?(u?(s)))))) __full_list_short_status__ | __pager__ ;;
	(-l|?(--)l?(i?(s?(t)))) __list_repos__ | __pager__ ;;
	(-f|?(--)f?(u?(l?(l))))  __full_list_full_status__ | __pager__ ;;
	(-u|?(--)upd?(a?(t?(e)))) __update_repos__ ;;
	(-U|?(--)upg?(r?(a?(d?(e))))) __upgrade_repos__ ;;
	('') __short_list_short_status__ ;; # Default behavio[u]r
	(*)  printf "%b\n" ""${_script_name}": Option \""${1:-}"\" not recognized."  1>&2 ; __show_help__ ; exit 2  1>&2 ;;
esac

# Main Script Wrapper
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
	trap __traperr__ ERR
	trap __ctrl_c__ INT
	trap __cleanup__ EXIT

	__main_script__


fi

exit 0
