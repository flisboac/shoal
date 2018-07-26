
semver_number() {
	printf "%s\n" "${1%%-*}"
}

semver_major() {
	semver_number_at "$1" 1
}

semver_minor() {
	semver_number_at "$1" 2
}

semver_patch() {
	semver_number_at "$1" 3
}

semver_number_at() {
    local ver; ver="$1"; shift
    local idx; idx="$1"; shift
    local version_num; version_num="$(semver_number "$ver")"; [ "$?" -ne 0 ] && return "$?"
	printf "$version_num\n" | awk "{split(\$0,a,\".\"); print(a[$idx]);}"
}

semver_ident() {
	local ident; ident="${1#*-}"; shift
	ident="${ident%%+*}"
	printf "%s\n" "$ident"
}

semver_build() {
	printf "%s\n" "${1#*+}"
}
