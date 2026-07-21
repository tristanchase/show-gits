#! /usr/bin/env bash

shopt -s globstar
shopt -s dotglob
shopt -s extglob

_script_name="dirty-state"
_arg=".git"
_git_array=( $(printf "%b\n" $HOME/**/ | grep "${_arg}"/$ | xargs dirname ) )
_sep=":"

function __git_status_state__ {
	git -C "${_dir}" status --branch  --porcelain=v2 | tr '\n' "${_sep}"
}

function __git_state_check__ {
_state=
for _dir in "${_git_array[@]}"; do
	_dirty_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status_state__)" | awk -F "${_sep}" '$6' )

	if [[ -n "${_dirty_out}" ]]; then
		_state="dirty"
		printf "%b\n" "${_dirty_out}" | awk -F "${_sep}" '{print $1" [files]"}'
	fi
done
}

function __git_status_stash__ {
	git -C "${_dir}" status  --show-stash --porcelain=v2 | tr '\n' "${_sep}"
}

function __git_stash_check__ {
_stash=
for _dir in "${_git_array[@]}"; do
	_stash_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status_stash__)" | awk -F "${_sep}" '$2' )

	if [[ -n "${_stash_out}" ]]; then
		_stash="stashed"
		printf "%b\n" "${_stash_out}" | awk -F "${_sep}" '{print $1" [stash]"}'
	fi
done
}

function __git_status_commits__ {
	git -C "${_dir}" rev-list --left-right @{upstream}...HEAD 2>/dev/null
}

function __git_commits_check__ {
_commits=
for _dir in "${_git_array[@]}"; do
	_commits_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status_commits__)" | awk -F "${_sep}" '$2')

	if [[ -n "${_commits_out}" ]]; then
		_commits="true"
		printf "%b\n" "${_commits_out}" | awk -F "${_sep}" '{print $1" [commits]"}'
	fi
done
}

__git_state_check__
__git_stash_check__
__git_commits_check__

if [[ -z "${_state}" ]]; then
	_state_msg="All working trees are clean. "
else
	_state_msg=''
fi

if [[ -z "${_stash}" ]]; then
	_stash_msg="Nothing is stashed. "
else
	_stash_msg=''
fi

if [[ -z "${_commits}" ]]; then
	_commits_msg="All repos are up to date. "
else
	_commits_msg=''
fi

if [[ -n "${_state_msg}" || -n "${_stash_msg}" || -n "${_commits_msg}" ]]; then
	printf "%b" ""${_script_name}": ${_state_msg}${_stash_msg}${_commits_msg}\n"
fi
