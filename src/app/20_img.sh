
import_img


__shoal_img_setup() {

    # This folder must always be a child of $imgroot_home
    img_home="$(pwd)"
}

__shoal_img_import() {

}

__shoal_img_importroot() {

    local __pwd; __pwd="$(pwd)"
    cd "$imgroot_home"
    . "$imgroot_rcfile"

    [ -z "$imgroot_maxdepth" ] && imgroot_maxdepth=4
    [ -z "$imgroot_mindepth" ] && imgroot_mindepth=1

    if [ -z "$imgroot_imgpaths" ]; then
        # FIX me
        imgroot_imgpaths="$imgroot_imgpaths;$(find "$imgroot_home" $(IFS=";"; for name in $shoal_cfg_imgspec; do printf -- '-name "%s" ' "$name"; done))"
    fi
    imgroot_imgpaths="${imgroot_imgpaths#;}"
}

__shoal_img_findroot() {

    local __searching; __searching=$YES
    local __err_not_folder; __err_not_folder=32 # Some arbitrary exitcode, intended to not conflict with anything else
    local __found; __found=$NO
    local __img_dir
    
    imgroot_home="$(pwd)"

    while is_true "$__searching"; do

        imgroot_rcfile=""

        if [ -f "$imgroot_home/imgrc.root" ]; then
            # If a file named imgrc.root is found on the dirname of the current
            # (or previous) images in the current image path (pwd), we stop searching.
            imgroot_rcfile="$imgroot_home/imgrc.root"
            __searching=$NO

        elif [ "$shoal_cfg_rootsearch_mode" = "imgrc" ] && [ -f "$imgroot_home/imgrc" ]; then
            imgroot_rcfile="$imgroot_home/imgrc"
            __img_dir="$(
                cd "$imgroot_home"
                . "$imgroot_rcfile"

                if is_var imgrc_rootdir; then
                    # Must always be absolute
                    cd "$imgrc_rootdir"
                    printf "%s\n" "$(pwd)"
                fi
            )"

            if [ "$?" -ne 0 ]; then
                die "Root directory declared in image resource '$imgroot_rcfile' is not valid."
            fi

            if [ ! -z "$__img_dir" ]; then
                if [ "${img_home##$__img_dir}" = "$img_home" ]; then
                    die "Invalid root directory for image '$imgroot_rcfile': Declared root directory '$__img_dir' is not a parent folder of the image home '$img_home'."
                fi

                imgroot_home="$__img_dir"
                __searching=$NO
            fi
        fi

        if [ "$imgroot_home" = "/" ]; then
            __searching=$NO

        elif is_true "$__searching"; then
            imgroot_home="$(dirname "$imgroot_home")"
        fi
    fi
}
