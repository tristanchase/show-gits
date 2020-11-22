
if [[ -e ~/.colors.sh ]]; then
	source ~/.colors.sh
fi

# Create temp file for output of find
# TODO Use array only?
_dirfile="${HOME}"/tmp/show-gits.$$.tempfile
touch ${_dirfile}

# Save current directory
_startdir="$(pwd)"

# Find the git repos in the ${HOME} directory (but exclude ~/.cache/)
printf "%b\n" ${HOME}/**/.git | sed 's/\/\.git//g' > ${_dirfile}
printf '%b\n' ${HOME}/.*/**/.git | grep -Ev '/\.(\.|cache)?/' | sed 's/\/\.git//g' >> ${_dirfile}

# Find files with trailing whitespace (but not .pdf's or other binary files)
function __find_trailing_whitespace(){
	if [[ -n "$(grep --files-with-matches --binary-files=without-match '\s$' 2>/dev/null "${_dir}"/*)" ]]; then
		printf "${WHT:-}${CYNB:-}%s\n" ">>>These files have trailing whitespace:"
		grep --files-with-matches --binary-files=without-match '\s$' 2>/dev/null "${_dir}"/* | xargs realpath
		printf ""${reset:-}"%b\n"
	fi
}

# Show git status à la git-prompt.sh
function __git_prompt {
	if [[ -e $HOME/.git-prompt.sh ]]; then
		source ~/.git-prompt.sh
		__git_ps1 2>/dev/null
	fi
}

# Get a list of the repos with the short status (default)
function __get_list_short(){
	for _dir in $(cat ${_dirfile}); do
		cd "${_dir}"
		printf ""${BBLU:-}"%s"${BCYN:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt)"
		git -C "${_dir}" status -s
		__find_trailing_whitespace
	done
}

# Show the repos (-l|--list)
function __show_repos(){
	#cat ${_dirfile}
	printf ""${BBLU:-}"%s\n"${reset:-}"" "$(cat ${_dirfile})"
}

# Update the repos from remote (-u|--update)
function __fetch_remotes(){
	for _dir in $(cat ${_dirfile}); do
		printf "%b\n" ${_dir}
		git -C "${_dir}" remote update
	done
}

# Get the full status of the repos (-f|--full)
function __get_full_status(){
	for _dir in $(cat ${_dirfile}); do
		#printf "%b\n" ${_dir}
		cd "${_dir}"
		#printf "%b\n" "${_dir}$(__git_prompt)"
		printf ""${BBLU:-}"%s"${BCYN:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt)"
		git -C "${_dir}" status
		__find_trailing_whitespace
		printf "%b\n" ""
	done
}

# Get the short status of the repos (-s|--status)
function __get_short_status() {
	for _dir in $(cat ${_dirfile}); do
		if [[ -n "$(git -C "${_dir}" status -s)" ]]; then
			#printf "%b\n" ${_dir}
			cd "${_dir}"
			#printf "%b\n" "${_dir}$(__git_prompt)"
			printf ""${BBLU:-}"%s"${BCYN:-}"%s\n"${reset:-}"" "${_dir}" "$(__git_prompt)"
			git -C "${_dir}" status -s
			__find_trailing_whitespace
		fi
	done
}

# Runtime
if [[ "${1:-}" =~ (-u|--update) ]]; then
	__fetch_remotes
elif [[ "${1:-}" =~ (-s|--status) ]]; then
	__get_short_status
elif [[ "${1:-}" =~ (-l|--list) ]]; then
	__show_repos | more
elif [[ "${1:-}" =~ (-f|--full) ]]; then
	__get_full_status | more
else
	__get_list_short | more
fi
# End runtime

# Return to the starting directory
cd ${_startdir}
