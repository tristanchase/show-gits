#!/usr/bin/env bash

# shellcheck disable=SC2317
function debug {
export PS4='+ [${BASH_SOURCE[0]}:${LINENO}]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -x
exec > >(tee debug) 2>&1
}

#debug
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

Description: Show the git repositories residing in ${HOME}

Options:
    #-d, [--]d[ebug]	Enable debug mode (disabled for now)
    -f, [--]f[ull]	Show full report of the repos
    -h, [--]h[elp]	Display this help message
    -l, [--]l[ist]	List the repos (without status)
    -o, [--]o[neline]	Display a list of the repos sorted be newest first
    -s, [--]s[tatus]	List the repos with short status
  [-]u, [--]upd[ate]	Update the repos from remote (git fetch)
  [-]U, [--]upg[rade]	Upgrade the repos from remote (git pull)

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

function __find_gits__ {
_grep_arg='/.git/$'
_git_array=( $(printf "%b\n" "${HOME}"/**/ | grep ${_grep_arg} | xargs dirname ) )
}

# Get the full status of the repos (-f|--full)
function __full_list_full_status__ {
	__find_gits__
	printf "%b\n" "Full status report:"
	for _dir in "${_git_array[@]}"; do
		printf "%b\n" "-----------------------------------"
		printf "%b\n" "${_dir}"
		printf "\n"
		git -C "${_dir}" status
		printf "\n"
	done
}

# Get a list of the repos with the short status (-s|--status)
function __full_list_short_status__ {
	__find_gits__
	for _dir in "${_git_array[@]}"; do
		printf "%b\n" "${_dir}"
		git -C "${_dir}" status -s
	done
}

# Show git status à la git-prompt.sh
#function __git_prompt__ {
#	if [[ "$(printf "%b\n" "$(__git_ps1__)" | grep '[\*\+%<>\$]')" ]]; then
#		_git_prompt_color="${bold_orange}"
#	else
#		_git_prompt_color="${bold_cyan}"
#	fi
#
#	printf "$(__git_ps1__)"
#}

function __git_ps1__ {
	__git_ps1 2>/dev/null
}

# Show the repos (-l|--list)
function __list_repos__ {
	__find_gits__
	for _dir in "${_git_array[@]}"; do
		printf "%b\n" "${_dir}"
	done
}

function __log_oneline__ {
	__find_gits__
	local _sep=","

	function __log_out__ {
		git -C "${_dir}" log -1 --format=format:'%as'"${_sep}"'%s'
	}

	_oneline_out=$( for _dir in "${_git_array[@]}"; do
			printf "%b%b\n" "${_dir}${_sep}" "$(__log_out__)"
		done )

	printf "%b\n" "${_oneline_out[@]}" | awk -F"${_sep}" -v awk_sep="${_sep}" '{print $2awk_sep$1awk_sep$3}' \
		| column -t -s"${_sep}" -o " | " | sort -t"|" -k1,1r | __pager__

}

function __pager__ {
  #${PAGER:-more -e}
  #more -e
  less -FXRM
}

# Get the short status of the repos (default)
function __short_list_short_status__ {
	__find_gits__
	for _dir in "${_git_array[@]}"; do
		cd "${_dir}"
		if [[ "$(printf "%b\n" "$(__git_ps1__)" | grep '[\*\+%<>\$]')" ]]; then
			printf "%b\n" "${_dir}"
			git -C "${_dir}" status -s
		fi
	done
}

function __z_dirty_state__ {
	_sep=":"

	_state_summary=
	_stash_summary=
	_commits_summary=

	_tempfile=temp-"${_script_name}" && touch "${_tempfile}"
	rm "${_tempfile}"

	function __git_check_all__ {
		__find_gits__
		for _dir in "${_git_array[@]}"; do
			_state=
			_stash=
			_commits=

			_state_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status_state__)" | awk -F "${_sep}" '$6' )
			_stash_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status_stash__)" | awk -F "${_sep}" '$2' )
			_commits_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status_commits__)" | awk -F "${_sep}" '$2' | awk '{print $1}' )

			if [[ -n "${_state_out}" ]]; then
				_num=$( printf "%b\n" "${_state_out}" | awk -F "${_sep}" '{print NF - 6}' )
				_state="[files:${_num}]"
				_state_summary="true"
			fi

			if [[ -n "${_stash_out}" ]]; then
				_num=$( printf "%b\n" "${_stash_out}" | awk -F "${_sep}" '{print $2}' )
				_stash="[stash:${_num}]"
				_stash_summary="true"
			fi

			if [[ -n "${_commits_out}" ]]; then
				_num_behind="<"$( printf "%b\n" "${_dir}" | git -C "${_dir}" status --branch --porcelain=v2 \
					| tr '\n' "${_sep}"| awk -F "${_sep}" '{print $4}' | awk '{print $4}' | cut -c2- )
				_num_ahead=$( printf "%b\n" "${_dir}" | git -C "${_dir}" status --branch --porcelain=v2 \
					| tr '\n' "${_sep}"| awk -F "${_sep}" '{print $4}' | awk '{print $3}' | cut -c2- )">"
				_commits="[commits:${_num_behind} ${_num_ahead}]"
				_commits_summary="true"
			fi

			if [[ -n "${_state}" || -n "${_stash}" || -n "${_commits}" ]]; then
				printf "%b" "${_dir}" | \
					awk -v awk_state="${_state}" -v awk_stash="${_stash}" -v awk_commits="${_commits}" -F "${_sep}" \
					'{print $1" " awk_state awk_stash awk_commits}'
			fi
		done
	}

	function __git_status_state__ {
		git -C "${_dir}" status --branch  --porcelain=v2 | tr '\n' "${_sep}"
	}

	function __git_status_stash__ {
		git -C "${_dir}" status --show-stash --porcelain=v2 | grep '# stash' | awk '{print $3}'
	}

	function __git_status_commits__ {
		git -C "${_dir}" rev-list --left-right @{upstream}...HEAD 2>/dev/null | tr '\n' "${_sep}"
	}

	function __summary__ {
		if [[ -z "${_state_summary}" ]]; then
			_state_msg="All working trees are clean. "
		else
			_state_msg=''
		fi

		if [[ -z "${_stash_summary}" ]]; then
			_stash_msg="Nothing is stashed. "
		else
			_stash_msg=''
		fi

		if [[ -z "${_commits_summary}" ]]; then
			_commits_msg="All repos are up to date. "
		else
			_commits_msg=''
		fi

		if [[ -n "${_state_msg}" || -n "${_stash_msg}" || -n "${_commits_msg}" ]]; then
			printf "%b" "${_script_name}: ${_state_msg}${_stash_msg}${_commits_msg}\n"
		fi
	}

	__git_check_all__
	__summary__
}

# Update the repos from remote (-u|--update)
function __update_repos__ {
	__find_gits__
	printf "%b\n" "${_git_array[@]}" | xargs -P 0 -I {} bash -c ' git -C {} remote update &>/dev/null && echo "{}... updated" '
}

# Upgrade the repos from remote (-U|--upgrade)
function __upgrade_repos__ {
	# Update the repos from remote
	__update_repos__

	_sep=":"

	function __git_status_commits__ {
		git -C "${_dir}" rev-list --left-right @{upstream}...HEAD 2>/dev/null | tr '\n' "${_sep}"
	}

	_upgrade_list=(
		$(for _dir in "${_git_array[@]}"; do
			printf "%b%b\n" "${_dir}${_sep}" "$(__git_status_commits__)" | awk -F "${_sep}" '$2' \
			| grep "<" | awk -F "${_sep}" '{print $1}'
		done
		)
	)

	if [[ -z "${_upgrade_list[*]}" ]]; then
		printf "%b\n" "${_script_name}: Repos are up to date."
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
	printf "\n"
	printf "%b\n" "The following ${_file_noun} can be upgraded (via git pull):"
	printf "  %s\n" "${_upgrade_list[@]}"
	printf "%b" "Would you like to upgrade ${_file_obj}? [Y/n] "
	read -r UPGRADE

	# Allow user to choose one, many, or all from the list
	# TODO Add chooser here (feat-chooser)

	# Upgrade repos
	if [[ ! "${UPGRADE}" =~ (n|N) ]]; then
		for _repo in "${_upgrade_list[@]}"; do
			cd "${_repo}" || printf "%b\n" "[${BASH_SOURCE[0]}:${LINENO}]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }cd: Error"; exit 3
			printf "%b\n" "Upgrading ${_repo}"
			git pull
			printf "\n"
		done
	fi
	exit 0

}

# Source helper functions
for _helper_file in functions colors git-prompt; do
	if [[ ! -e "${HOME}"/."${_helper_file}".sh ]]; then
		printf "%b\n" "Downloading missing script file ${_helper_file}.sh..."
		sleep 1
		wget -nv -P "${HOME}" https://raw.githubusercontent.com/tristanchase/dotfiles/main/"${_helper_file}".sh
		mv "${HOME}"/"${_helper_file}".sh "${HOME}"/."${_helper_file}".sh
	fi
done

#source "${HOME}"/.functions.sh
source "${HOME}"/.git-prompt.sh

# Get some basic options
# TODO Make this more robust (use getopt? I kinda like the vim-like style) (refactor-options-getopt)
# refactor: rewrite options using getopt (refactor-options-getopt)
case "$1" in
	#(-d|?(--)d?(e?(b?(u?(g))))) debug "$@" ;;
	(-h|?(--)h?(e?(l?(p))) ) __show_help__ ;;
	(-s|?(--)s?(t?(a?(t?(u?(s))))) ) __full_list_short_status__ | __pager__ ;;
	(-l|?(--)l?(i?(s?(t))) ) __list_repos__ | __pager__ ;;
	(-f|?(--)f?(u?(l?(l))) )  __full_list_full_status__ | __pager__ ;;
	(-o|?(--)o?(n?(e?(l?(i?(n?(e)))))) ) __log_oneline__ ;;
	?(-)u|?(--)upd?(a?(t?(e))) ) __update_repos__ ;;
	?(-)U|?(--)upg?(r?(a?(d?(e)))) ) __upgrade_repos__ ;;
	('') __z_dirty_state__ ;; # Default behavio[u]r
	#('') __short_list_short_status__ ;; # Default behavio[u]r
	(*)  printf "%b\n" "${_script_name}: Option \"${1:-}\" not recognized."  1>&2 ; __show_help__ ;;
esac

exit 0
