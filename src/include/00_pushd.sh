
if ! command -v 'pushd' >/dev/null; then
    # For Dash and friends
    pushd() {
        local dirname; dirname="$1"; shift

        if [ -z "$dirname" ]; then
            printf "* Missing directory path.\n" >&2
            return "$EXIT_FAILURE"
        elif [ ! -d "$dirname" ]; then
            printf "* Path '$dirname' is not a directory or does not exist.\n" >&2
            return "$EXIT_FAILURE"
        fi

        f__DIRSTACK_="$(pwd)\n$f__DIRSTACK_"
        cd "$dirname" || return "$EXIT_FAILURE"
        printf "$(pwd)\n$f__DIRSTACK_"
    }

    popd() {
        local top
        local old_stack

        old_stack="$f__DIRSTACK_"
        top="${f__DIRSTACK_%%\\n*}"
        f__DIRSTACK_="${f__DIRSTACK_#*\\n}"

        if [ ! -z "$top" ]; then
            cd "$top" || return "$EXIT_FAILURE"
            printf "$old_stack"
        else
            printf "* Directory stack is empty.\n" >&2
            return "$EXIT_FAILURE"
        fi
    }
fi
