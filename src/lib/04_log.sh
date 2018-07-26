
readonly EXIT_SUCCESS=0

readonly LOG_TRACE=10
readonly LOG_DEBUG=20
readonly LOG_INFO=50
readonly LOG_WARN=70
readonly LOG_ERROR=90
readonly LOG_FATAL=100

alias loglv="loglv_simple"
alias log='loglv "$LOG_DEFAULT"'
alias tlog='loglv "$LOG_TRACE"'
alias dlog='loglv "$LOG_DEBUG"'
alias ilog='loglv "$LOG_INFO"'
alias wlog='loglv "$LOG_WARN"'
alias elog='loglv "$LOG_ERROR"'
alias flog='loglv "$LOG_FATAL"'

[ -z "$EXIT_FAILURE" ] && EXIT_FAILURE=1
[ -z "$EXIT_LOGLN" ] && EXIT_LOGLN="flog"

[ -z "$STDOUT" ] && STDOUT="&1"
[ -z "$STDERR" ] && STDERR="&2"
[ -z "$STDLOG" ] && STDLOG="$STDERR"
[ -z "$LOG_LEVEL" ] && LOG_LEVEL="$LOG_WARN"
[ -z "$LOG_DEFAULT" ] && LOG_DEFAULT="$LOG_DEFAULT"
[ -z "$LOG_FORMAT"] && LOG_FORMAT="%s\t%s\t%s\t%s\t%s\t%s"

[ -z "$ESC_BLACK"   ] && ESC_BLACK='\033[0;30m'
[ -z "$ESC_GRAY"    ] && ESC_GRAY='\033[1;30m'
[ -z "$ESC_LGRAY"   ] && ESC_LGRAY='\033[0;37m'
[ -z "$ESC_WHITE"   ] && ESC_WHITE='\033[1;37m'
[ -z "$ESC_RED"     ] && ESC_RED='\033[0;31m'
[ -z "$ESC_LRED"    ] && ESC_LRED='\033[1;31m'
[ -z "$ESC_GREEN"   ] && ESC_GREEN='\033[0;32m'
[ -z "$ESC_LGREEN"  ] && ESC_LGREEN='\033[1;32m'
[ -z "$ESC_ORANGE"  ] && ESC_ORANGE='\033[0;33m'
[ -z "$ESC_YELLOW"  ] && ESC_YELLOW='\033[1;33m'
[ -z "$ESC_BLUE"    ] && ESC_BLUE='\033[0;34m'
[ -z "$ESC_LBLUE"   ] && ESC_LBLUE='\033[1;34m'
[ -z "$ESC_PURPLE"  ] && ESC_PURPLE='\033[0;35m'
[ -z "$ESC_LPURPLE" ] && ESC_LPURPLE='\033[1;35m'
[ -z "$ESC_CYAN"    ] && ESC_CYAN='\033[0;36m'
[ -z "$ESC_LCYAN"   ] && ESC_LCYAN='\033[1;36m'
[ -z "$ESC_NOCOLOR" ] && ESC_NOCOLOR='\033[0m' # No Color

if [ ! -z "$LOG_NOCOLOR" ]; then
    C_BLACK=""
    C_GRAY=""
    C_LGRAY=""
    C_WHITE=""
    C_RED=""
    C_LRED=""
    C_GREEN=""
    C_LGREEN=""
    C_ORANGE=""
    C_YELLOW=""
    C_BLUE=""
    C_LBLUE=""
    C_PURPLE=""
    C_LPURPLE=""
    C_CYAN=""
    C_LCYAN=""
    C_NOCOLOR=""
else
    C_BLACK="$ESC_BLACK"
    C_GRAY="$ESC_GRAY"
    C_LGRAY="$ESC_LGRAY"
    C_WHITE="$ESC_WHITE"
    C_RED="$ESC_RED"
    C_LRED="$ESC_LRED"
    C_GREEN="$ESC_GREEN"
    C_LGREEN="$ESC_LGREEN"
    C_ORANGE="$ESC_ORANGE"
    C_YELLOW="$ESC_YELLOW"
    C_BLUE="$ESC_BLUE"
    C_LBLUE="$ESC_LBLUE"
    C_PURPLE="$ESC_PURPLE"
    C_LPURPLE="$ESC_LPURPLE"
    C_CYAN="$ESC_CYAN"
    C_LCYAN="$ESC_LCYAN"
    C_NOCOLOR="$ESC_NOCOLOR"
fi

# Prints to STDOUT
print() { printf "$@" >"$STDOUT"; }
println() { local fmt; fmt="$1\n"; shift; print "$fmt" "$@"; }
# Prints to STDLOG (Default output for logging)
lprint() { printf "$@" >"$STDLOG"; }
lprintln() { local fmt; fmt="$1\n"; shift; log "$fmt" "$@"; }
# Prints to STDERR
eprint() { printf "$@" >"$STDLOG"; }
eprintln() { local fmt; fmt="$1\n"; shift; eprint "$fmt" "$@"; }

abort() {
    local exitcode; exitcode="$1"; shift
    [ "$#" -gt 0 ] && "$EXIT_LOGLN" "$@"
    exit "$exitcode"
}

bye() {
    abort "$EXIT_SUCCESS" "$@"
}

die() {
    abort "$EXIT_FAILURE" "$@"
}

log_lvtoname() {
    [ "$lv" -le "$LOG_TRACE" ] && echo "TRACE"
    [ "$lv" -le "$LOG_DEBUG" ] && echo "DEBUG"
    [ "$lv" -le "$LOG_INFO" ] && echo "INFO"
    [ "$lv" -le "$LOG_WARN" ] && echo "WARN"
    [ "$lv" -le "$LOG_ERROR" ] && echo "ERROR"
    echo "FATAL"
}

is_loggable_lv() { echo "$(test "$1" -lt "$LOG_LEVEL")" }
log_getwhen() { date -u -I ns; }
log_getwhere() { hostname; }
log_getpid() { echo $$; }
log_getsubject() { echo "(basename "$0")"; }

loglv_simple() {
    local lv
    local msg
    local tpl
    lv="$1"; shift
    [ ! is_loggable_lv "$lv" ] && return
    if [ "$#" -gt 0 ]; then
        tpl="$1"; shift;
        printf "$tpl" "$@" | read msg
        [ "$?" -ne 0 ] && msg="$tpl"
    fi
    log_write_simple "$lv" "$msg"
}

log_write_simple() {
    local lv; lv="$1"; shift
    local msg; lv="$1"; shift
    lprintln "*** $(log_lvtoname "$lv"): $msg"
}

loglv_full() {
    local lv
    local when
    local where
    local pid
    local subject
    local msg
    local tpl
    local line
    lv="$1"; shift
    [ ! is_loggable_lv "$lv" ] && return
    log_getwhen | read when
    log_getwhere | read where
    log_getpid | read pid
    log_getsubject | read proc
    if [ "$#" -gt 0 ]; then
        tpl="$1"; shift;
        printf "$tpl" "$@" | read msg
        [ "$?" -ne 0 ] && msg="$tpl"
    fi
    log_write_full "$lv" "$when" "$where" "$pid" "$subject" "$msg"
}

log_write_full() {
    local lv; lv="$1"; shift
    local when; when="$1"; shift
    local where; where="$1"; shift
    local pid; pid="$1"; shift
    local subject; subject="$1"; shift
    local msg; msg="$1"; shift
    lprintln "$LOG_FORMAT" "$lv" "$when" "$where" "$pid" "$subject" "$msg"
}

