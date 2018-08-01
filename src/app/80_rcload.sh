
shoal_init() {

    [ ! -z "$shoal_initialized" ] && return 0
    
    local IFS
    local old_IFS; old_IFS="$IFS"

    shoal_phase="rcinit"

    shoal_imported_exts="${shoal_imported_exts#;}"
    shoal_imported_imgs=""

    shoal_syscfg_home="${SHOAL_CFG_HOME:-/etc/shoal}"
    shoal_usercfg_home="${SHOAL_USERCFG_HOME:-~/.config/shoal}"

    [ -f "$shoal_syscfg_home/shoal.conf" ] && . "$shoal_syscfg_home/shoal.conf"
    [ -f "$shoal_usercfg_home/shoal.conf" ] && . "$shoal_usercfg_home/shoal.conf"

    PATH="$shoal_user_bindir:$shoal_sys_bindir:$PATH"
    shoal_cfg_extpath="${SHOAL_EXTPATH:-$shoal_sys_extdir;$shoal_user_extdir}"
    shoal_cfg_imgpath="${SHOAL_IMGPATH:-$shoal_sys_imgdir;$shoal_user_imgdir}"
    #shoal_cfg_extspec="${SHOAL_EXTSPEC:-*.ext.sh}"
    shoal_cfg_imgspec="${SHOAL_IMGSPEC:-imgrc.d;imgrc}"
    shoal_cfg_rootsearch_mode="${SHOAL_ROOTSEARCH_MODE:-imgrc}"
    shoal_cfg_imgroot_maxdepth="${SHOAL_ROOT_MAXDEPTH:-4}"
    shoal_cfg_imgroot_mindepth="${SHOAL_ROOT_MINDEPTH:-0}"

    shoal_sys_home="${SHOAL_HOME:-/usr/local/share/shoal}"
    shoal_sys_bindir="${SHOAL_BINDIR:-$shoal_sys_home/bin}"
    shoal_sys_libdir="${SHOAL_LIBDIR:-$shoal_sys_home/lib}"
    shoal_sys_extdir="${SHOAL_EXTDIR:-$shoal_sys_home/ext}"
    shoal_sys_imgdir="${SHOAL_IMGDIR:-$shoal_sys_home/img}"

    shoal_user_home="${SHOAL_USER_HOME:-~/.local/share/shoal}"
    shoal_user_bindir="${SHOAL_USER_BINDIR:-$shoal_user_home/bin}"
    shoal_user_libdir="${SHOAL_USER_LIBDIR:-$shoal_user_home/lib}"
    shoal_user_extdir="${SHOAL_USER_EXTDIR:-$shoal_user_home/ext}"
    shoal_user_imgdir="${SHOAL_USER_IMGDIR:-$shoal_user_home/img}"

    if [ -z "$SHOAL_CREATEDIRS" ] || [ "$SHOAL_CREATEDIRS" eq 0 ]; do
        [ -w "$(dirname "$shoal_user_bindir")" ] && [ ! -e "$shoal_user_bindir" ] && mkdir -p "$shoal_user_bindir"
        [ -w "$(dirname "$shoal_user_libdir")" ] && [ ! -e "$shoal_user_libdir" ] && mkdir -p "$shoal_user_libdir"
        [ -w "$(dirname "$shoal_user_extdir")" ] && [ ! -e "$shoal_user_extdir" ] && mkdir -p "$shoal_user_extdir"
        [ -w "$(dirname "$shoal_user_imgdir")" ] && [ ! -e "$shoal_user_imgdir" ] && mkdir -p "$shoal_user_imgdir"

        [ -w "$(dirname "$shoal_sys_bindir")" ] && [ ! -e "$shoal_sys_bindir" ] && mkdir -p "$shoal_sys_bindir"
        [ -w "$(dirname "$shoal_sys_libdir")" ] && [ ! -e "$shoal_sys_libdir" ] && mkdir -p "$shoal_sys_libdir"
        [ -w "$(dirname "$shoal_sys_extdir")" ] && [ ! -e "$shoal_sys_extdir" ] && mkdir -p "$shoal_sys_extdir"
        [ -w "$(dirname "$shoal_sys_imgdir")" ] && [ ! -e "$shoal_sys_imgdir" ] && mkdir -p "$shoal_sys_imgdir"
    fi

    if [ ! -z "$SHOAL_USER" ]; then
        shoal_uid="${SHOAL_UID:-$(id -u "$SHOAL_USER" 2>/dev/null)}"
        shoal_uname="${SHOAL_UNAME:-$(id -un "$SHOAL_USER" 2>/dev/null)}"
    else
        shoal_uid="${SHOAL_UID:-$(id -u 2>/dev/null)}"
        shoal_uname="${SHOAL_UNAME:-$(id -un 2>/dev/null)}"
    fi
    
    if [ -z "$shoal_uid" ] || [ -z "$shoal_uname"]; then
        die "Could not detect user's ID and/or name."
    fi
    
    # Importing all non-project libraries
    __shoal_import_syslibs
    __shoal_import_userlibs

    # Setting up all non-project images

    # Setting up root
    __shoal_img_findroot
    __shoal_img_findrootrc
    __shoal_img_setuproot

    IFS=";"; for extension in $shoal_extensions; do
        unset IFS
        if is_runnable "ext_${extension}_init"; then
            "ext_${extension}_init"
        fi
    done; IFS="$old_IFS"

    shoal_initialized=0
}

# Global command
shoal_main() {

    shoal_init
}


