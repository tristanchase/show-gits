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

_tempfile=temp-"${_script_name}" && touch "${_tempfile}"
rm "${_tempfile}"

# Copy from here into show-gits.sh as a function
function __log_oneline__ {
	_sep=":"

	function __log_out__ {
		git -C "${_dir}" log -1 --format=format:'%as'"${_sep}"'%s'
		#git -C "${_dir}" log -1 --oneline
	}

	_oneline_out=( $( for _dir in "${_git_array[@]}"; do
			printf "%b%b\n" "${_dir}${_sep}" "$(__log_out__)"
		done )
	)

	printf "%b\n" "${_oneline_out[*]}" | awk -F"${_sep}" '{print $0}' | sort -t"${_sep}" -k2,2n

	#printf "%b\n" "${_oneline_out[@]}" | awk -F"${_sep}" '{print $0}' | sort -t"${_sep}" -k2,2n
}

__log_oneline__
