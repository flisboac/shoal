

# domain-name-style URLs guaranteed to work! IPv4, maybe, but certainly not IPv6!
# No support for parameters yet
url_part() {
	local url; url="$1"; shift
	local part; part="$1"; shift
	local prot cred user pass host auth port path frag
	prot="$(echo "$url" | grep '://' | sed -e's,^\(.*://\).*,\1,g')"
	url="$(echo "$url" | sed "s;^$prot;;")"
	frag="$(echo "$url" | cut -d\# -f2)"
	url="$(echo "$url" | cut -d\# -f1)"
	cred="$(echo "$url" | grep @ | cut -d@ -f1)"
	user="$(echo "$cred" | sed 's;:.*$;;')"
	pass="$(echo "$cred" | sed 's;^.*:;;')"
	auth="$(echo "$url" | sed "s;$cred@;;" | cut -d/ -f1)"
	host="$(echo "$auth" | sed "s;:.*$;;")"
	port="$(echo "$auth" | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
	path="$(echo "$url" | grep / | cut -d/ -f2-)"
	case "$part" in
		prot) printf "$prot\n" ;;
		cred) printf "$cred\n" ;;
		user) printf "$user\n" ;;
		pass) printf "$pass\n" ;;
		auth) printf "$auth\n" ;;
		host) printf "$host\n" ;;
		port) printf "$port\n" ;;
		path) printf "$path\n" ;;
		frag) printf "$frag\n" ;;
		*) echo "Unknown URL part '$part'." >&2; return 1 ;;
	esac
	return 0
}

url_encode() {
	local string="${1}"; shift
	local strlen="$(echo "$string" | wc -m)"
	local encoded=""
	local pos=0
	local c
	local o

	while [ "$pos" -lt "$((strlen-1))" ]; do
		pos="$((pos+1))"
		c="$(echo "$string" | awk "{s=substr(\$0,$pos,1); print s}")"
		case "$c" in
		[-_.~a-zA-Z0-9] ) o="${c}" ;;
		* )               o="$(printf '%%%02x' "'$c")"
		esac
		encoded="${encoded}${o}"
	done
	echo "${encoded}"
}

url_download() {
    # TODO
    false
}
