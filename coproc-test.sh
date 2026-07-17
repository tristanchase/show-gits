#!/usr/bin/env bash

shopt -s globstar dotglob
shopt -s extglob

_arg='.git'
_chooser_array=( $(printf "%b\n" $HOME/**/ | grep "${_arg}"/$ | xargs dirname ) )

coproc GIT_UPDATE {
	while read -r line; do
	#for line in $dir; do
		echo "${line}"
		git -C "${line}" remote update &
	done
}

exec {GIT_UPDATE_IN}>&"${GIT_UPDATE[1]}"
exec {GIT_UPDATE_OUT}<&"${GIT_UPDATE[0]}"


for dir in "${_chooser_array[@]}"; do
	#printf "%b\n" $dir

	#git -C $dir remote update

	echo "${dir}" >&"${GIT_UPDATE_IN}"
	read -r response <&"${GIT_UPDATE_OUT}"
	echo $response


done

#wait "$GIT_UPDATE_PID"
exec {GIT_UPDATE_IN}>&-
exec {GIT_UPDATE_OUT}<&-

kill "$GIT_UPDATE_PID" 2>/dev/null
