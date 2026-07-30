#!/usr/bin/env bash

function debug {
export PS4='+ [${BASH_SOURCE}:${LINENO}]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -x
exec > >(tee debug) 2>&1
}

#debug

shopt -s globstar
shopt -s dotglob
shopt -s extglob

_script_name=$(basename -s .sh "$0")
_grep_arg='/.git/$'
_git_array=( $(printf "%b\n" $HOME/**/ | grep "${_grep_arg}" | xargs dirname ) )

# Copy from here into show-gits.sh as a function
function __z_dirty_state__ {
_sep=":"

_state_summary=
_stash_summary=
_commits_summary=

_tempfile=temp-"${_script_name}" && touch "${_tempfile}"
rm "${_tempfile}"

function __git_check_all__ {
	for _dir in "${_git_array[@]}"; do
		_state=
		_stash=
		_commits=

		_state_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status_state__)" | awk -F "${_sep}" '$6' )
		_stash_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status_stash__)" | awk -F "${_sep}" '$2' )
		_commits_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status_commits__)" | awk -F "${_sep}" '$2' | awk '{print $1}' )

		if [[ -n "${_state_out}" ]]; then
			_num=$( printf "%b\n" "${_state_out}" | awk -F "${_sep}" '{print NF - 6}' )
			_state="[files:"${_num}"]"
			_state_summary="true"
		fi

		if [[ -n "${_stash_out}" ]]; then
			_num=$( printf "%b\n" "${_stash_out}" | awk -F "${_sep}" '{print $2}' )
			_stash="[stash:"${_num}"]"
			_stash_summary="true"
		fi

		if [[ -n "${_commits_out}" ]]; then
			_num_behind="<"$( printf "%b\n" "${_dir}" | git -C "${_dir}" status --branch --porcelain=v2 \
			       	| tr '\n' "${_sep}"| awk -F "${_sep}" '{print $4}' | awk '{print $4}' | cut -c2- )
			_num_ahead=$( printf "%b\n" "${_dir}" | git -C "${_dir}" status --branch --porcelain=v2 \
			       	| tr '\n' "${_sep}"| awk -F "${_sep}" '{print $4}' | awk '{print $3}' | cut -c2- )">"
			_commits="[commits:"${_num_behind}" "${_num_ahead}"]"
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
		printf "%b" ""${_script_name}": ${_state_msg}${_stash_msg}${_commits_msg}\n"
	fi
}

__git_check_all__
__summary__
}

__z_dirty_state__
