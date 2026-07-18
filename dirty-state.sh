#! /usr/bin/env bash

shopt -s globstar
shopt -s dotglob
shopt -s extglob

_script_name="dirty-state"
_arg='.git'
_git_array=( $(printf "%b\n" $HOME/**/ | grep "${_arg}"/$ | xargs dirname ) )

state=''
for dir in "${_git_array[@]}"; do
	dirty_out=$( git -C "${dir}" update-index --really-refresh && git diff-index --quiet HEAD -- )
	if [[ -n "${dirty_out}" ]]; then
		state='dirty'
		printf "%b" ""${dir}" "${dirty_out}"\n"
		git -C "${dir}" status -s
	fi
done

if [[ -z "${state}" ]]; then
	printf "%b\n" ""${_script_name}": All working trees are clean."
fi
#dirty_out=$( git update-index --really-refresh && git diff-index --quiet HEAD -- )

#echo $?
#echo $dirty_out
