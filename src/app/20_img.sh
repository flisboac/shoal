
import_img() {
    
    if [ -z "$shoal_phase" ] || [ "$shoal_phase" = 'rcinit' ]; then

    fi
}

__shoal_img_importl() {

    img_path="$(__shoal_imgpath_resolvel "$1")" || return "$?"; shift
    img_home="$imgroot_home$img_path"
    img_variant=""

    img_rcfile="$(__shoal_img_makercfile)" || die
    __shoal_img_loadrc
}

__shoal_img_importgv() {

    [ -z "$img_home" ] && die "Image not initialized yet!"
    img_variant="$1"; shift

    img_rcfile="$(__shoal_img_makercfile)" || die
    __shoal_img_loadrc
}

__shoal_imgpath_resolvel() {
    
    local __1; __1="$1"
    local __imgpath; __imgpath="$__1"; shift
    local __imghome

    [ -z "$__imgpath" ] && die "Invalid image path, cannot be empty."

    if [ "$__imgpath" = "/" ]; then
        true

    elif [ -z "${__imgpath##/*}" ]; then
        # Image path is relative to the project's root
        __imgpath="${__imgpath##/}"
        __imgpath="${__imgpath%%/}"
        [ -z "$__imgpath" ] && die "It seems that this image path contained only forward slashes... Maybe some substitutions went wrong? Check your sources!"
        __imgpath="/$__imgpath"

    elif [ -z "${__imgpath##.*}" ]; then
        # Image path is relative to current folder
        __imghome="$(cd "$__imgpath"; pwd)"
        __imgpath="${__imghome#$imgroot_home}"
        [ "$__imgpath" = "$__imghome" ] && die "Image path '$__imgpath' points to a directory outside the project root '$imgroot_home'."
    fi

    [ -z "$__imgpath" ] && die "Image path '$__1' locally resolved to an empty string."

    printf "%s\n" "$__imgpath"
}

__shoal_img_makercfile () {

    local __basedir; __basedir=""
    local __variant; __variant=""
    local __rcfile; __rcfile=""

    if [ "$#" -gt 0 ]; then
        __basedir="$1"; shift
        if [ "$#" -gt 0 ]; then
            __variant="$1"; shift
        fi
    else
        [ -z "$__basedir" ] && __basedir="$img_home"
        [ -z "$__variant" ] && __variant="$img_variant"
    fi

    if [ -z "$__variant" ]; then
        if [ -e "$__basedir/$__imgpath" ]; then
            __rcfile="$__basedir/imgrc"
        elif if [ -e "$__basedir/imgrc.d/imgrc" ]; then
            __rcfile="$__basedir/imgrc.d/imgrc"
        fi
    else
        if [ -e "$__basedir/imgrc-$__variant" ]; then
            __rcfile="$__basedir/imgrc-$__variant"
        elif if [ -e "$__basedir/imgrc.d/imgrc-$__variant" ]; then
            __rcfile="$__basedir/imgrc.d/imgrc-$__variant"
        fi
    fi

    [ ! -z "$__rcfile" ] && __shoal_validate_project_rcfile "$__rcfile"
    printf "%s\n" "$__rcfile"
}

__shoal_img_setuproot() {

    local IFS
    local __pwd; __pwd="$(pwd)"
    local __imgpath

    if [ ! -z "$imgroot_rcfile" ]; then
        imgroot_phase="init"
        cd "$imgroot_home"
        . "$imgroot_rcfile"
        cd "$__pwd"
        unset imgroot_phase
    fi

    [ -z "$imgroot_maxdepth" ] && imgroot_maxdepth="$shoal_cfg_imgroot_maxdepth"
    [ -z "$imgroot_mindepth" ] && imgroot_mindepth="$shoal_cfg_imgroot_mindepth"
    
    [ "$imgroot_mindepth" -lt 0 ] && die "File '$imgroot_rcfile': $$imgroot_mindepth must not be less than 0 (current value: '$imgroot_mindepth')."
    [ "$imgroot_maxdepth" -lt "$imgroot_mindepth" ] && die "File '$imgroot_rcfile': $$imgroot_maxdepth (value: $imgroot_maxdepth) shouldnot be less than $$imgroot_mindepth (value: $imgroot_mindepth)."

    if [ -z "$imgroot_imgpaths" ]; then
        IFS=";"; for imgspec in $shoal_cfg_imgspec; do
            unset IFS
            for file in $(find "$imgroot_home" -mindepth "$imgroot_mindepth" -maxdepth "$imgroot_maxdepth" -name "$imgspec" | sort | uniq); do
                __imgpath="$(dirname "${file#$imgroot_home}")" # This variable substitution here only works because $imgroot_home is guaranteed to be an absolute path
                # { [ __imgpath = "." ] || [ __imgpath = "./" ]; } && __imgpath="/"
                imgroot_imgpaths="$imgroot_imgpaths;$__imgpath"
            done
        done; unset IFS
    fi
    imgroot_imgpaths="${imgroot_imgpaths#;}"
}

__shoal_img_findroot() {

    local __searching; __searching=$YES
    local __err_not_folder; __err_not_folder=32 # Some arbitrary exitcode, intended to not conflict with anything else
    local __found; __found=$NO
    local __img_dir
    local __pwd; __pwd="$(pwd)"
    
    [ -z "$imgroot_home" ] && imgroot_home="${SHOAL_IMGROOT_HOME}"

    if [ -z "$imgroot_home" ]; then
        imgroot_home="$__pwd"

        while is_true "$__searching"; do

            imgroot_rcfile=""

            if [ -e "$imgroot_home/imgrc.root" ]; then
                # If a file named imgrc.root is found on the dirname of the current
                # (or previous) images in the current image path (pwd), we stop searching.
                # It may just be empty.
                imgroot_rcfile="$imgroot_home/imgrc.root"
                __searching=$NO

            elif [ "$shoal_cfg_rootsearch_mode" = "imgrc" ]; then
            
                imgroot_rcfile="$(__shoal_img_makercfile  "$imgroot_home")" || die
                
                if [ -z "$imgroot_rcfile" ]; then
                    __img_dir="$(
                        imgroot_phase="search"
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
            fi

            if is_true "$__searching"; then
                if [ "$imgroot_home" = "/" ]; then
                    __searching=$NO
                    imgroot_rcfile=""
                    dlog "The image root folder could not be found. Defaulting to the current folder '$__pwd'."
                    imgroot_home="$__pwd"
                else
                    imgroot_home="$(dirname "$imgroot_home")"
                fi
            fi
        fi
    fi

    [ -z "$imgroot_home" ] && die "Could not find the image root's home directory."
    [ ! -d "$imgroot_home" ] && die "The project's root folder '$imgroot_home' must be a directory."
    [ ! -r "$imgroot_home" ] && die "The project's root folder '$imgroot_home' is not readable."
    [ ! -x "$imgroot_home" ] && die "The project's root folder '$imgroot_home' is not executable (cannot list contents)."
}

__shoal_img_findrootrc() {

    if [ -z "$imgroot_rcfile" ]; then
        if [ -e "$imgroot_home/imgrc.root" ]; then
            imgroot_rcfile="$imgroot_home/imgrc.root"
        elif [ -e "$imgroot_home/imgrc" ]; then
            imgroot_rcfile="$imgroot_home/imgrc"
        fi
    fi

    __shoal_validate_project_rcfile "$imgroot_rcfile"
}

__shoal_validate_rcfile() {
    local __rcfile; __rcfile="$1"; shift

    if [ ! -z "$__rcfile" ]; then
        [ ! -f "$__rcfile" ] && die "Image rcfile '$__rcfile' must be a file."
        [ ! -r "$__rcfile" ] && die "Image rcfile '$__rcfile' is not readable."
    fi
}

__shoal_validate_project_rcfile() {
    local __rcfile; __rcfile="$1"; shift

    [ -z "$imgroot_home" ] && die "$$imgroot_home is empty!"
    [ "${imgroot_rcfile#$imgroot_home}" = "$imgroot_rcfile" ] && die "The root rcfile '$imgroot_rcfile' is not a child of the project's root folder '$imgroot_home'."
    __shoal_validate_rcfile "$__rcfile"
}

__shoal_img_loadrc() {

    local __pwd; __pwd="$(pwd)"

    cd "$img_home"
    . "$img_rcfile"
    cd "$__pwd"

    # TODO Variable checking
}

__shoal_img_runphase() {

    # TODO implementation
    false
}
