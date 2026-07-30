#!/usr/bin/env bash

function debug {
export PS4='+ [${BASH_SOURCE}:${LINENO}]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -x
exec > >(tee debug) 2>&1
}

shopt -s globstar
shopt -s dotglob
shopt -s extglob

_script_name=$(basename -s .sh "$0")
_grep_arg='/.git/$'
_git_array=( $(printf "%b\n" $HOME/**/ | grep "${_grep_arg}" | xargs dirname ) )

printf "%b\n" "${_git_array[@]}" | xargs -I {} bash -c ' printf "%b :" "{}" 2>&1 && git -C {} log -1 --oneline '
