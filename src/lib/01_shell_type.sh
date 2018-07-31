

current_shell() {
    ps -p $$ -ocomm= 2>/dev/null
}

typeof_shell() {
    local shell_name
    # Could use:
    # [ ! -z "$BASH" ] && echo "bash" && return
    # [ ! -z "$ZSH_NAME" ] && echo "zsh" && return
    shell_name="$(basename "$(current_shell)" 2>/dev/null)"
    [ ! -z "$shell_name" ] && printf "$shell_name\n" && return
    # May never reach here
    echo "sh"
}

set_posix() {
    case "$(typeof_shell)" in
    bash) set -o posix ;;
    esac
}

unset_posix() {
    case "$(typeof_shell)" in
    bash) set +o posix ;;
    esac
}
