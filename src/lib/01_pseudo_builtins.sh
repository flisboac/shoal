

#
# CONSTANTS
#

readonly YES=0
readonly NO=1

[ -z "$SHELL_HAS_TYPE_T" ] && SHELL_HAS_TYPE_T="$(type -t 'if' 2>/dev/null >/dev/null; echo "$?")"
[ -z "$SHELL_HAS_READ_S" ] && SHELL_HAS_READ_S="$(echo "\n" | read -s 'if' 2>/dev/null >/dev/null; echo "$?")"


typeof() {
	local elem; elem="$1"; shift
	local typeinfo
	local typeid
	local exitcode

	if [ "$SHELL_HAS_TYPE_T" -eq 0 ]; then
        type -t "$elem"
        exitcode="$?"
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
		fi
	fi

    if [ "$exitcode" -ne 0 ]; then
        if is_var "$elem"; then
            echo "var"
            exitcode=0
        fi
    fi

    [ "$exitcode" -ne 0 ] && echo ""
    return "$exitcode"
}

is_true() {
    return "$(test "$1" -eq 0; echo "$?")"
}

is_false() {
    return "$(test "$1" -ne 0; echo "$?")"
}

is_success() {
    is_true "$?"
}

is_failure() {
    is_false "$?"
}

is_function() {
    [ "$(typeof "$1")" = "function" ] && return $YES
    return $NO
}

is_alias() {
    [ "$(typeof "$1")" = "alias" ] && return $YES
    return $NO
}

is_executable() {
    [ -x "$(command -v "$1")" ] && return $YES
    return $NO
}

# For all intents and purposes, this function consider an alias to contain an
# executable or part of a valid command.
is_runnable() {
    if is_function "$1" || is_alias "$1" || is_executable "$1"; then
        return $YES
    fi
    return $NO
}

opt_name() {
    var_name "$(printf "$1\n" | sed 's;^-*;;')"
}

opt_value() {
    var_value "$(printf "$1\n" | sed 's;^-*;;')"
}

opt_value() {
    local value
    value="$(echo "$1" | grep '=')"
    printf "${value#*=}\n"
}

var_name() {
    printf "${1%%=*}\n"
}

var_value() {
    local value
    value="$(echo "$1" | grep '=')"
    printf "${value#*=}\n"
}

to_VARNAME() {
	local env_name; env_name="$(to_envname "$@")"
	[ "$?" -ne 0 ] && return "$?"
	printf "%s\n" "$env_name" | tr '[:lower:]' '[:upper:]'
}

to_varname() {
	local opt_suffix=""
	[ "$#" -eq 0 ] && return 1
	local name; name="$1"; shift
	[ "$#" -gt 0 ] && opt_suffix="$1" && shift
	local tr_name; tr_name="$(printf "%s" "$name" | tr '(\s\t|[:punct:])' '_' | tr -d '[:space:]')"
	[ ! -z "$tr_name" ] && tr_name="$tr_name$opt_suffix"
	printf "%s\n" "$tr_name"
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
