#! /usr/bin/env bash

shopt -s globstar
shopt -s dotglob
shopt -s extglob

_script_name="dirty-state"
_arg=".git"
_git_array=( $(printf "%b\n" $HOME/**/ | grep "${_arg}"/$ | xargs dirname ) )
_tempfile="$HOME/tmp/"${_script_name}".$(date +%T)"
_sep=":"

function __git_status__ {
	#git -C "${_dir}" status --porcelain=v1 | tr '\n' "${_sep}"
	git -C "${_dir}" status --branch  --porcelain=v2 | tr '\n' "${_sep}"
	#git -C "${_dir}" status  --show-stash --porcelain=v2 | tr '\n' "${_sep}"
	#git rev-list --left-right @{upstream}...HEAD
}

#_state=""
for _dir in "${_git_array[@]}"; do
	#printf "%b%b\n" "${_dir}${_sep}" "$(__git_status__ | tr '\n' "${_sep}")" >> "${_tempfile}"
	#printf "%b%b\n" "${_dir}${_sep}" "$(__git_status__ | tr '\n' "${_sep}")" | awk -F "${_sep}" '$2' >> "${_tempfile}"
	_dirty_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status__)" | awk -F "${_sep}" '$6' )

	#_dirty_out=$( git -C "${dir}" update-index --really-refresh && git diff-index --quiet HEAD -- )
	if [[ -n "${_dirty_out}" ]]; then
		_state="dirty"
		#printf "%b\n" "${_dirty_out}"
		printf "%b\n" "${_dirty_out}" | awk -F "${_sep}" '{print $1" [files]"}'
	fi
done

#if [[ -z "${_state}" ]]; then
#	printf "%b\n" ""${_script_name}": All working trees are clean."
#	_state="All working trees are clean."
#fi

#TODO make the next functions work
#_commits=""
for _dir in "${_git_array[@]}"; do
	#printf "%b%b\n" "${_dir}${_sep}" "$(__git_status__ | tr '\n' "${_sep}")" >> "${_tempfile}"
	#printf "%b%b\n" "${_dir}${_sep}" "$(__git_status__ | tr '\n' "${_sep}")" | awk -F "${_sep}" '$2' >> "${_tempfile}"
	_dirty_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status__)" | awk -F "${_sep}" '$6' )

	#_dirty_out=$( git -C "${dir}" update-index --really-refresh && git diff-index --quiet HEAD -- )
	if [[ -n "${_dirty_out}" ]]; then
		_state="dirty"
		#printf "%b\n" "${_dirty_out}"
		printf "%b\n" "${_dirty_out}" | awk -F "${_sep}" '{print $1" [files]"}'
	fi
done

#if [[ -z "${_state}" ]]; then
#	printf "%b\n" ""${_script_name}": All working trees are clean."
#	_state="All working trees are clean."
#fi

#_stash=""
for _dir in "${_git_array[@]}"; do
	#printf "%b%b\n" "${_dir}${_sep}" "$(__git_status__ | tr '\n' "${_sep}")" >> "${_tempfile}"
	#printf "%b%b\n" "${_dir}${_sep}" "$(__git_status__ | tr '\n' "${_sep}")" | awk -F "${_sep}" '$2' >> "${_tempfile}"
	_dirty_out=$( printf "%b%b\n" "${_dir}${_sep}" "$(__git_status__)" | awk -F "${_sep}" '$6' )

	#_dirty_out=$( git -C "${dir}" update-index --really-refresh && git diff-index --quiet HEAD -- )
	if [[ -n "${_dirty_out}" ]]; then
		_state="dirty"
		#printf "%b\n" "${_dirty_out}"
		printf "%b\n" "${_dirty_out}" | awk -F "${_sep}" '{print $1" [files]"}'
	fi
done

# TODO make this work if everything is up to date
#if [[ -z "${_state}" ]]; then
#	printf "%b\n" ""${_script_name}": All working trees are clean."
#	_state="All working trees are clean."
#fi



#rm "${_tempfile}"
