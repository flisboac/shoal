
try_run() {
    local cmd; cmd="$1"; shift
    local fallback_cmd; fallback_cmd="$1"; shift
    if is_runnable "$cmd"; then
        "$cmd" "$@"
    else
        "$fallback_cmd" "$@"
    fi
}
