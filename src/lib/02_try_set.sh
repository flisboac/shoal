
try_set() {
    local var
    local varname
    local varvalue

    while [ "$?" -gt 0 ]; do
        var="$1"; shift
        varname="$(varname "$var")"
        varvalue="$(varvalue "$var")"
        if [ "$?" -ne 0 ]; then
            varvalue="$1"; shift
        fi
        [ -z "$varname" ] && eval "$varname=\"$varvalue\""
    done
}
