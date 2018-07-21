#!/bin/sh

# ... Just so we don't need make inside a docker image (e.g. build-essential)
# We have a pretty simple use-case here.

[ -z "$DESTDIR" ] && DESTDIR=build/install
[ -z "$BUILDDIR" ] && BUILDDIR=build

readonly SRCDIR="$(dirname "$0")"

all() {
    build && install
}

clean() {
    if [ ! "$SRCDIR" = "$BUILDDIR" ]; then
        rm -rf "$BUILDDIR"
    fi
}

build() {
    mkdir -p "$DESTDIR" && \
    mkdir -p "$BUILDDIR" && \
    printf "#!${SHELL:-/bin/sh}\n" > "$BUILDDIR/shoal" && \
    LANG=POSIX cat src/include/*.sh | grep -v '^\s*#' >> "$BUILDDIR/shoal" && \
    cat src/*.sh | grep -v '^\s*#' >> "$BUILDDIR/shoal" && \
    chmod 0555 "$BUILDDIR/shoal"
}

install() {
    false;
}

main() {
    local target

    if [ "$?" -eq 0 ]; then
        all
    else
        while [ "$?" -gt 0 ]; do
            target="$1"; shift

            case "$1" in
                all) all ;;
                build) build ;;
                install) install ;;
                clean) clean ;;
                *=*) eval "$1" ;; # TODO Use some pattern matching, e.g. grep '[a-zA-Z_0-9]+=.*'
                *) echo "* Unknown target '$1'." >&2; exit 1 ;;
            esac || break
        done
    fi
}

main "$@"