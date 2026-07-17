#!/usr/bin/env bash

shopt -s globstar dotglob
shopt -s extglob

_arg='.git'
#_chooser_array=( $(printf "%b\n" $HOME/**/ | grep "${_arg}"/$ | xargs dirname ) )
printf "%b\n" $HOME/**/ | grep "${_arg}"/$ | xargs dirname | xargs -P 16 -I {} sh -c ' git -C {} remote update > /dev/null && echo "{}...updated"'


