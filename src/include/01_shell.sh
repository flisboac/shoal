

#
# CONSTANTS
#

readonly SHELL_HAS_TYPE_T="$(type -t 'if' 2>/dev/null >/dev/null; echo "$?")"
readonly SHELL_HAS_READ_S="$(echo "\n" | read -s 'if' 2>/dev/null >/dev/null; echo "$?")"

typeof() {
	local elem; elem="$1"; shift
	local typeinfo
	local typeid
	local exitcode

	if [ "$SHELL_HAS_TYPE_T" -eq 0 ]; then
        type -t "$elem"

    else
		typeinfo="$(LANG=C command -V "$elem" 2>/dev/null)"
		exitcode="$?"
		typeinfo="$(echo "$typeinfo" | sed 's/^.*is //')"
		if [ "$exitcode" -eq 0 ]; then
			if ( echo "$typeinfo" | grep "a shell keyword" >/dev/null ); then echo "keyword"
			elif ( echo "$typeinfo" | grep "a shell function" >/dev/null ); then echo "function"
			elif ( echo "$typeinfo" | grep "is an alias for" >/dev/null ); then echo "alias"
			elif ( echo "$typeinfo" | grep "a shell builtin" >/dev/null ); then echo "builtin"
			else echo "file"
			fi
		else
			echo ""
		fi
		return "$exitcode"
	fi
}


read_password() {
	local var; var="$1"; shift
	local msg
	local cmd
	if [ "$#" -gt 0 ]; then
		msg="$1"; shift
		cmd="-p \"$msg\" \"$var\""
	else
		cmd="\"$var\""
	fi
	if [ "$SHELL_HAS_READ_S" -eq 0 ]; then
		eval "read -s $cmd"
	else
		stty -echo
		eval "read $cmd"
		printf \\n
		stty echo
	fi
}

to_ENVNAME() {
	local env_name; env_name="$(to_envname "$@")"
	[ "$?" -ne 0 ] && return "$?"
	printf "%s\n" "$env_name" | tr '[:lower:]' '[:upper:]'
}

to_envname() {
	local opt_suffix=""
	[ "$#" -eq 0 ] && return 1
	local name; name="$1"; shift
	[ "$#" -gt 0 ] && opt_suffix="$1" && shift
	local tr_name; tr_name="$(printf "%s" "$name" | tr '(\s\t|[:punct:])' '_' | tr -d '[:space:]')"
	[ ! -z "$tr_name" ] && tr_name="$tr_name$opt_suffix"
	printf "%s\n" "$tr_name"
}
