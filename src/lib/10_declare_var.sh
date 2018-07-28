

declare_var() {

    local help_content
    { help_content="$(cat)"; } <<"HELP"
An environment variable declaration helper.
An action will be performed per ASSIGNMENT or VARNAME given, in order, if the
tests provided succeed for said variable.

USAGE:
  $ declare_var [TEST_OPTION]... [ACT_OPTION] [MOD_OPTION]... [--] <VARNAME|ASSIGNMENT>...

Where `--` instructs `declare_var` to stop parsing options.
Where VARNAME is a variable name.
Where ASSIGNMENT has the format of a variable assignment, e.g. `VARNAME=VALUE`.

Where TEST_OPTION is one of:
  -d, --if-defined      : Perform action only if variable is defined.
  -D, --if-not-defined  : Perform action only if variable is NOT defined.
  -e, --if-empty        : Perform action only if variable substitution 
                          evaluates to an empty string.
  -E, --if-not-empty    : Perform action only if variable substitution
                          DOES NOT evaluate to an empty string.
  -X, --if-not-export   : If the variable is defined, succeeds only if it's
                          also exported. Does NOT imply `-d`.
  -T, --test=TEST       : Specifies a custom test script. Should be an alias, function
                          or executable. The script will receive a variable name and
                          MUST return a zero exitcode if the test succeeds, or non-zero
                          if not.

Where ACT_OPTION is one of:
  -n, --print-name      : Do NOT perform assignment; instead, print the
                          names of variables that passed the test.
  -N, --print-fail-name : Do NOT perform assignment; instead, print the
                          names of variables that DID NOT pass the test.
      --dry-run         : Do NOT perform assignment; instead, print to
                          STDOUT all assignment commands that would be perform.
      --action=ACTION   : Specifies a different action. Should be a runnable of
                          some kind (alias, function or executable). Only ONE
                          action is supported. See Remarks.

Where MOD_OPTION is one of:
      --all               : Succeeds only if ALL tests succeed. This is the default.
      --any               : Succeeds if any test succeed.
  -x, --export            : If assignment is performed, also export the variable.
  -u, --to-upper          : Transforms the name to uppercase.
      --to-lower          : Transforms the name to lowercase.
      --name=NAME_PAT     : Specifies a printf-based name pattern, receiving a
                            single '%s' argument that is a VARNAME. 
                            MUST evaluate to a valid variable name. Defaults to '%s'.
      --prefix=PREFIX     : Specifies the name prefix. Defaults to "".
                            Applied after `--name` and before `--to-{upper|lower}`
      --suffix=SUFFIX     : Specifies the name suffix. Defaults to "".
                            Applied after `--name` and before `--to-{upper|lower}`
      --presuf=PRESUF     : Specifies both prefix and suffix at the same time.
      --value=VALUE       : Specifies the default value to assume if:
                            1. Test succeeds; and
                            2. Variable value evaluates to empty; and
                            3. No default value is given for that var (not an ASSIGNMENT).
                            Does NOT accept empty values.
      --undef-value=VALUE : Specifies the default value to assume if:
                            1. Test succeeds; and
                            2. Variable is undefined; and
                            3. No default value is given for that var (not an ASSIGNMENT).
                            Has precedence over `--value`. Does NOT accept empty values.
Remarks:
  This script DOES NOT intend to substitute `declare`, `set`, `env` or `export`.
  Use them when more appropriate.

  Short options that take no parameter can be joined together into a single 
  short option, e.g. `declare_var -dEx SOME_VAR=value`.

  TEST_OPTION, ACT_OPTION and MOD_OPTION can be given in any order, but 
  VARNAME|ASSIGNMENT must follow ALL options.

  Only ONE ACT_OPTION should be given. Anything may happen if more than one is
  provided (undefined behaviour)!

  If more than one TEST_OPTION is given, the action will be performed only
  if all of the predicates evaluate to true.

  If NO TEST_OPTION is given, success is assumed for all variables.

  If ACTION is given, the passed script name will receive, as arguments:
    1. The *variable locality*, that is one of:
      - 'export': an exported global variable.
      - 'global': a global, non-exported variable.
    2. The *variable type*. At the time, will be an empty string, to denote no
       specific typing;
    2. The *variable name*; and
    3. Optionally (if given or detected), the *variable's value*. Will not be given
       if the variable is undefined and no default value was provided.
HELP

    local IFS
    local custom_test_sep; custom_test_sep=":"

    local exitcode; exitcode=0
    local parsing; parsing=0
    local v
    local n
    local varname
    local value
    local cmd
    local assign_value
    local is_defined
    local is_empty
    local is_export
    local is_custom_success
    local success

    local testing_undef; testing_undef=""
    local testing_empty; testing_empty=""
    local testing_export; testing_export=""
    local custom_tests; custom_tests=""

    local name_pattern; name_pattern=""
    local name_prefix; name_prefix=""
    local name_suffix; name_suffix=""
    local name_transformation; name_transformation=""
    local name_export; name_export=""

    local test_mode; test_mode="all"
    local test_action; test_action="assign" # possible values: assign, name, fail-name, dry-run, custom
    local default_value; default_value=""
    local default_undef_value; default_undef_value=""
    local custom_action; custom_action=""

    [ "$#" -eq 0 ] && printf "$help_content\n" >&2 && return 1

    while [ "$#" -gt 0 ] && [ "$parsing" -eq 0 ]; do
        case "$1" in
        -h|--help) echo "$help_content"; return 0 ;;
        -d|--if-defined) testing-undef=0; shift ;;
        -D|--if-not-defined) testing-undef=1; shift ;;
        -e|--if-empty) testing_empty=0; shift ;;
        -E|--if-not-empty) testing_empty=1; shift ;;
        -X|--if-not-export) testing_export=1; shift ;;
        -T|--test) shift; if [ -z "$custom_tests" ]; then custom_tests="$1"; else custom_tests="$custom_tests$custom_test_sep$1"; fi; shift ;;
        --test=*) v="${1#*=}"; if [ -z "$custom_tests" ]; then custom_tests="$v"; else custom_tests="$custom_tests$custom_test_sep$v"; fi; shift ;;
        -T*) v="${1#-T}"; if [ -z "$custom_tests" ]; then custom_tests="$v"; else custom_tests="$custom_tests$custom_test_sep$v"; fi; shift ;;
        -n|--print-name) test_action="name"; shift ;;
        -N|--print-fail-name) test_action="fail-name"; shift ;;
        --dry-run) test_action="dry-run"; shift ;;
        --action) shift; test_action="custom"; custom_action="$1"; shift ;;
        --action=*) shift; test_action="custom"; custom_action="${1#*=}"; shift ;;
        --any) test_mode="any"; shift ;;
        --all) test_mode="all"; shift ;;
        -x|--export) name_export="export"; shift ;;
        -u|--to-upper) name_transformation="tr '[:lower:]' '[:upper:]'"; shift ;;
        --to-lower) name_transformation="tr '[:upper:]' '[:lower:]'"; shift ;;
        --name) shift; name_pattern="$1"; shift ;;
        --name=*) name_pattern="${1#*=}"; shift ;;
        --prefix) shift; name_prefix="$1"; shift ;;
        --prefix=*) name_prefix="${1#*=}"; shift ;;
        --suffix) shift; name_suffix="$1"; shift ;;
        --suffix=*) name_suffix="${1#*=}"; shift ;;
        --presuf) shift; name_prefix="$1", name_suffix="$1"; shift ;;
        --presuf=*) v="${1#*=}"; name_prefix="$v"; name_suffix="$v"; shift ;;
        --value) shift; default_value="$1"; shift ;;
        --value=*) default_value="${1#*=}"; shift ;;
        --undef-value) shift; default_undef_value="$1"; shift ;;
        --undef-value=*) default_undef_value="${1#*=}"; shift ;;

        --*) echo "* ERROR: Invalid option '$1'." >&2; return 1 ;;
        --) parsing=1; shift ;;
        -*)
            n=0; v="${1#-}"; shift
            ( echo "$v" | grep 'h' >/dev/null ) && echo "$help_content" && return 0
            ( echo "$v" | grep 'd' >/dev/null ) && n=$((n+1)) && testing_undef=0
            ( echo "$v" | grep 'D' >/dev/null ) && n=$((n+1)) && testing_undef=1
            ( echo "$v" | grep 'e' >/dev/null ) && n=$((n+1)) && testing_empty=0
            ( echo "$v" | grep 'E' >/dev/null ) && n=$((n+1)) && testing_empty=1
            ( echo "$v" | grep 'X' >/dev/null ) && n=$((n+1)) && testing_export=1
            ( echo "$v" | grep 'n' >/dev/null ) && n=$((n+1)) && test_action="name"
            ( echo "$v" | grep 'N' >/dev/null ) && n=$((n+1)) && test_action="fail-name"
            ( echo "$v" | grep 'x' >/dev/null ) && n=$((n+1)) && name_export="export"
            ( echo "$v" | grep 'u' >/dev/null ) && n=$((n+1)) && name_transformation="tr '[:lower:]' '[:upper:]'"
            [ "$n" -ne "$(printf "%s" "$v" | wc -m)" ] && echo "* ERROR: Invalid option in '-$v'." >&2; return 1 ;;
            ;;
        *) parsing=1;
        esac
    done

    [ "$#" -eq 0 ] && \
        printf "* ERROR: No variable name or assignment provided.\n" >&2 && \
        printf "$help_content\n" >&2 && \
        return 1
    
     while [ "$#" -gt 0 ] && [ "$exitcode" -eq 0 ]; do
        v="$1"; shift
        
        if printf "%s" "$v" | grep '=' >/dev/null; then
            varname="${v%%=*}"
            assign_value="${v#*=}"
        else
            varname="${v}"
            assign_value=""
        fi

        varname="$name_prefix$(printf "$name_pattern" "$varname")$name_suffix"
        [ ! -z "$name_transformation" ] && varname="$(printf "$varname" | $name_transformation)"
        value="$(eval "printf \"%s\" \"\$$varname\"")"
        
        if [ ! -z "$testing_empty" ]; then
            is_empty="$([ -z "$value" ]; echo "$?")"
        else
            is_empty=0
        fi

        if [ ! -z "$testing_undef" ]; then
            is_defined="$(set | grep "^$varname=" >/dev/null 2>/dev/null; echo "$?")"
        else
            is_defined=0
        fi

        if [ ! -z "$testing_export" ]; then
            is_export="$(export -p | grep "$varname=" >/dev/null 2>/dev/null; echo "$?")"
        else
            is_export=0
        fi

        if [ ! -z "$custom_tests" ]; then

        else
            is_custom_success=0
        fi

        if [ "$test_mode" == "any" ]; then
            [ "$is_empty" -eq 0 ] || \
                [ "$is_defined" -eq 0 ] || \
                [ "$is_export" -eq 0 ] || \
                [ "$is_custom_success" -eq 0 ]
            success="$?"
        else
            [ "$is_empty" -eq 0 ] && \
                [ "$is_defined" -eq 0 ] && \
                [ "$is_export" -eq 0 ] && \
                [ "$is_custom_success" -eq 0 ]
            success="$?"
        fi

        if [ -z "$assign_value" ]; then
            if [ "$is_defined" -ne 0 ]; then
                assign_value="$default_undef_value"
            elif [ -z "$value" ]; then
                assign_value="$default_value"
            else
                assign_value="$value"
            fi
        fi

        [ ! -z "$name_export" ] && cmd="$name_export"
        cmd="${cmd}${varname}"
        [ ! -z "$assign_value" ] && cmd="${cmd}=${assign_value}"

        if [ "$cmd" = "$varname"]; then
            echo "* WARN: Skipping variable '$varname', nothing to do." >$2
            exitcode=1
            continue
        fi
        
        case "$test_mode" in
        assign)
            eval "$cmd";
            exitcode="$?"
            [ "$exitcode" -ne 0 ] && continue
            ;;
        name)
            [ "$success" -eq 0 ] && printf "$varname\n"
            ;;
        fail-name)
            [ "$success" -ne 0 ] && printf "$varname\n"
            ;;
        dry-run)
            printf "%s\n" "$cmd"
            ;;
        custom)
            if [ ! -z "$name_export" ]; then
                $custom_action "export" "$varname" "$assign_value"
            else
                $custom_action "global" "$varname" "$assign_value"
            fi
            ;;
        esac
    done

    return "$exitcode"
}
