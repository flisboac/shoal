

declare_var() {

    local help_content
    { help_content="$(cat)"; } <<"HELP"
An environment variable declaration helper.
An action will be performed per ASSIGNMENT or VARNAME given, in order, if the
tests provided succeed for said variable.

USAGE:
------

  $ declare_var [TEST_OPTION]... [ACT_OPTION] [MOD_OPTION]... [--] <VARNAME|ASSIGNMENT>...

Where `--` instructs `declare_var` to stop _declare_var__parsing options.
Where VARNAME is a variable name.
Where ASSIGNMENT has the format of a variable assignment, e.g. `VARNAME=VALUE`.

Where TEST_OPTION is one of:
  -d, --if-defined        : Perform action only if variable is defined.
  -D, --if-not-defined    : Perform action only if variable is NOT defined.
  -e, --if-empty          : Perform action only if variable substitution 
                            evaluates to an empty string.
  -E, --if-not-empty      : Perform action only if variable substitution
                            DOES NOT evaluate to an empty string.
  -X, --if-not-export     : If the variable is defined, succeeds only if it's
                            also exported. Does NOT imply `-d`.
  -R, --if-not-readonly   : If the variable is defined, succeeds only if it's
                            not readonly. Does NOT imply `-d`.
  -T, --test=TEST         : Specifies a custom test script. Should be an alias, 
                            function or executable. The script will receive a
                            variable name and MUST return a zero exitcode if the
                            test succeeds, or non-zero if not.

Where ACT_OPTION is one of:
  -n, --print-name        : Do NOT perform assignment; instead, print the
                            names of variables that passed the test.
  -N, --print-fail-name   : Do NOT perform assignment; instead, print the
                            names of variables that DID NOT pass the test.
  -S, --action=ACTION     : Specifies an action script. Should be an alias or
                            runnable of some kind (alias, function or executable).
                            Only ONE action is supported. See Remarks.
  -s, --action-alias=AA   : A simpler `--action`. Receives a single ASSIGNMENT.
                            See Remarks.

Where MOD_OPTION is one of:
      --dry-run           : Do NOT perform assignment; instead, print to
                            STDOUT all assignment commands that would be perform.
      --all               : Succeeds only if ALL tests succeed. This is the default.
      --any               : Succeeds if any test succeed.
  -x, --export            : If assignment is performed, also export the variable.
  -r, --readonly          : If assignment is performed, make it `readonly`.
  -u, --to-upper          : Transforms the name to uppercase.
      --to-lower          : Transforms the name to lowercase.
      --name=NAME_PAT     : Specifies a printf-based name pattern, receiving a
                            single '%s' argument that is a VARNAME. 
                            MUST evaluate to a valid variable name.
                            Defaults to '%s'.
      --prefix=PREFIX     : Specifies the name prefix. Defaults to "".
                            Applied after `--name` and before `--to-{upper|lower}`
      --suffix=SUFFIX     : Specifies the name suffix. Defaults to "".
                            Applied after `--name` and before `--to-{upper|lower}`
      --presuf=PRESUF     : Specifies both prefix and suffix at the same time.
      --value=VALUE       : Specifies the default value to assume if:
                            1. Test succeeds; and
                            2. Variable value evaluates to empty; and
                            3. No default value is given for that var (not 
                               an ASSIGNMENT).
                            Does NOT accept empty values.
      --undef-value=VALUE : Specifies the default value to assume if:
                            1. Test succeeds; and
                            2. Variable is undefined; and
                            3. No default value is given for that var (not 
                               an ASSIGNMENT).
                            Has precedence over `--value`.
                            Does NOT accept empty values.
REMARKS:
--------

  This script DOES NOT intend to substitute `declare`, `set`, `env` or `export`.
  Use them when more appropriate.


  Short options that take no parameter can be joined together into a single 
  short option, e.g. `declare_var -dEx SOME_VAR=VALUE`. TEST_OPTION, ACT_OPTION 
  and MOD_OPTION can be given in any order, but VARNAME|ASSIGNMENT must follow 
  ALL options. If NO TEST_OPTION is given, test success is assumed for all
  variables. Only ONE ACT_OPTION should be given.


  Each assignment, if occurring, happens immediately, and in order.
  If any assignment fails, the program stops and returns a non-zero value.
  To substitute a variable in the default given for a following variable, you
  must escape one dollar sign, and ensure the name can be correctly substituted.
  Example:
    $ declare_var SUBJECT=world MESSAGE="Hello, $${SUBJECT}!"
  This would result in the following statements in the CURRENT shell/process,
  in this exact order:
    $ SUBJECT="world"
    $ MESSAGE="Hello, ${SUBJECT}!"
  

  If ACTION is given, the passed script name will receive, as arguments:
    1. The *variable flags*, separated by ':' that is one of:
      - Locality: 'export', 'global' or 'local'
      - Accessibility: 'readonly' (read-only) or 'rw' (read-writable)
      - Type: 'string' (string)
    2. The *variable name*; and
    3. Optionally (if given or detected), the *variable's value*. Will not be 
       given if the variable is undefined and no default value was provided.
       

  `--action-alias` is just an alias for a command that can declare the variable
  when needed. The user may lose the flexibility and power of `--action` in
  exchange for ease of use for simpler cases. For example, to declare read-only
  variables with defaults (for when the variable doesn't have a value defined):
    $ declare_var -s readonly \
        MYLIB_HOME=/usr/local/share/mylib \
        MILIB_BIN_DIR=$$MYLIB_HOME/bin
  Then, for each variable in the list, it'll detect the value (and fallback to
  the values provided, if empty), and issue `readonly`statements, e.g.:
    $ readonly MYLIB_HOME=/usr/local/share/mylib
    $ readonly MYLIB_BIN_DIR=$MYLIB_HOME/bin

!!!WARNING!!!:
--------------
  This program makes extensive use of `eval`-like functionality, and therefore,
  IT IS NOT (entirely) *SAFE*. Use declare_var only in controlled environments
  (e.g. with guaranteed input argument cleanup/sanitizing).


HELP

    local IFS
    local _declare_var__custom_test_sep; _declare_var__custom_test_sep=":"

    local _declare_var__exitcode; _declare_var__exitcode=0
    local _declare_var__parsing; _declare_var__parsing=0
    local _declare_var__v
    local _declare_var__n
    local _declare_var__varname
    local _declare_var__value
    local _declare_var__cmd
    local _declare_var__assign_value
    local _declare_var__is_defined
    local _declare_var__is_empty
    local _declare_var__is_export
    local _declare_var__is_readonly
    local _declare_var__is_custom_success
    local _declare_var__is_dry_run; _declare_var__is_dry_run=1
    local _declare_var__is_declaring_export; _declare_var__is_declaring_export=1
    local _declare_var__is_declaring_readonly; _declare_var__is_declaring_readonly=1
    local _declare_var__is_success

    local _declare_var__testing_defined; _declare_var__testing_defined=""
    local _declare_var__testing_empty; _declare_var__testing_empty=""
    local _declare_var__testing_export; _declare_var__testing_export=""
    local _declare_var__testing_readonly; _declare_var__testing_readonly=""
    local _declare_var__custom_tests; _declare_var__custom_tests=""

    local _declare_var__name_pattern; _declare_var__name_pattern="%s"
    local _declare_var__name_prefix; _declare_var__name_prefix=""
    local _declare_var__name_suffix; _declare_var__name_suffix=""
    local _declare_var__name_transformation; _declare_var__name_transformation=""
    local _declare_var__name_kind; _declare_var__name_kind=""

    local _declare_var__test_mode; _declare_var__test_mode="all"
    local _declare_var__test_action; _declare_var__test_action="assign" # possible values: assign, name, fail-name, custom, custom-prefix
    local _declare_var__default_value; _declare_var__default_value=""
    local _declare_var__default_undef_value; _declare_var__default_undef_value=""
    local _declare_var__custom_action; _declare_var__custom_action=""

    [ "$#" -eq 0 ] && printf "$help_content\n" >&2 && return 1

    while [ "$#" -gt 0 ] && [ "$_declare_var__parsing" -eq 0 ]; do
        case "$1" in
        -h|--help) echo "$help_content\n"; return 0 ;;

        -d|--if-defined) testing_undef=0; shift ;;
        -D|--if-not-defined) testing_undef=1; shift ;;
        -e|--if-empty) _declare_var__testing_empty=0; shift ;;
        -E|--if-not-empty) _declare_var__testing_empty=1; shift ;;
        -X|--if-not-export) _declare_var__testing_export=1; shift ;;
        -R|--if-not-readonly) _declare_var__testing_readonly=1; shift ;;

        -T|--test)
            shift;
            if [ -z "$_declare_var__custom_tests" ];
            then _declare_var__custom_tests="$1";
            else  _declare_var__custom_tests="$_declare_var__custom_tests$_declare_var__custom_test_sep$1";
            fi; shift ;;
        --test=*) 
            _declare_var__v="${1#*=}";
            if [ -z "$_declare_var__custom_tests" ];
            then _declare_var__custom_tests="$_declare_var__v";
            else _declare_var__custom_tests="$_declare_var__custom_tests$_declare_var__custom_test_sep$_declare_var__v";
            fi; shift ;;
        -T*) 
            _declare_var__v="${1#-T}";
            if [ -z "$_declare_var__custom_tests" ];
            then _declare_var__custom_tests="$_declare_var__v";
            else _declare_var__custom_tests="$_declare_var__custom_tests$_declare_var__custom_test_sep$_declare_var__v";
            fi; shift ;;

        -n|--print-name) _declare_var__test_action="name"; shift ;;
        -N|--print-fail-name) _declare_var__test_action="fail-name"; shift ;;

        -S|--action) shift; _declare_var__test_action="custom"; _declare_var__custom_action="$1"; shift ;;
        -S*) _declare_var__test_action="custom"; _declare_var__custom_action="${1#-S}"; shift ;;
        --action=*) shift; _declare_var__test_action="custom"; _declare_var__custom_action="${1#*=}"; shift ;;

        -s|--action-alias) shift; _declare_var__test_action="custom-prefix"; _declare_var__custom_action="$1"; shift ;;
        -s*) _declare_var__test_action="custom-prefix"; _declare_var__custom_action="${1#-s}"; shift ;;
        --action-alias=*) shift; _declare_var__test_action="custom-prefix"; _declare_var__custom_action="${1#*=}"; shift ;;

        --any) _declare_var__test_mode="any"; shift ;;
        --all) _declare_var__test_mode="all"; shift ;;
        --dry-run) _declare_var__is_dry_run=0; shift ;;
        -x|--export) _declare_var__is_declaring_export=0; shift ;;
        -r|--readonly) _declare_var__is_declaring_readonly=0; shift ;;
        -u|--to-upper) _declare_var__name_transformation="tr '[:lower:]' '[:upper:]'"; shift ;;
        --to-lower) _declare_var__name_transformation="tr '[:upper:]' '[:lower:]'"; shift ;;
        
        --name) shift; _declare_var__name_pattern="$1"; shift ;;
        --name=*) _declare_var__name_pattern="${1#*=}"; shift ;;

        --prefix) shift; _declare_var__name_prefix="$1"; shift ;;
        --prefix=*) _declare_var__name_prefix="${1#*=}"; shift ;;

        --suffix) shift; _declare_var__name_suffix="$1"; shift ;;
        --suffix=*) _declare_var__name_suffix="${1#*=}"; shift ;;

        --presuf) shift; _declare_var__name_prefix="$1", _declare_var__name_suffix="$1"; shift ;;
        --presuf=*) _declare_var__v="${1#*=}"; _declare_var__name_prefix="$_declare_var__v"; _declare_var__name_suffix="$_declare_var__v"; shift ;;

        --value) shift; _declare_var__default_value="$1"; shift ;;
        --value=*) _declare_var__default_value="${1#*=}"; shift ;;

        --undef-value) shift; _declare_var__default_undef_value="$1"; shift ;;
        --undef-value=*) _declare_var__default_undef_value="${1#*=}"; shift ;;

        --*) echo "* ERROR: Invalid option '$1'." >&2; return 1 ;;
        --) _declare_var__parsing=1; shift ;;
        -*)
            _declare_var__n=0; _declare_var__v="${1#-}"; shift
            ( printf "%s" "$_declare_var__v" | grep 'h' >/dev/null ) && echo "$help_content" && return 0
            ( printf "%s" "$_declare_var__v" | grep 'd' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__testing_defined=0
            ( printf "%s" "$_declare_var__v" | grep 'D' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__testing_defined=1
            ( printf "%s" "$_declare_var__v" | grep 'e' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__testing_empty=0
            ( printf "%s" "$_declare_var__v" | grep 'E' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__testing_empty=1
            ( printf "%s" "$_declare_var__v" | grep 'X' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__testing_export=1
            ( printf "%s" "$_declare_var__v" | grep 'R' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__testing_readonly=1
            ( printf "%s" "$_declare_var__v" | grep 'n' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__test_action="name"
            ( printf "%s" "$_declare_var__v" | grep 'N' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__test_action="fail-name"
            ( printf "%s" "$_declare_var__v" | grep 'x' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__is_declaring_export=0
            ( printf "%s" "$_declare_var__v" | grep 'r' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__is_declaring_readonly=0
            ( printf "%s" "$_declare_var__v" | grep 'u' >/dev/null ) && _declare_var__n=$((_declare_var__n+1)) && _declare_var__name_transformation="tr '[:lower:]' '[:upper:]'"
            [ "$_declare_var__n" -ne "$(printf "%s" "$_declare_var__v" | wc -m)" ] && echo "* ERROR: Invalid option in '-$_declare_var__v'." >&2 && return 1
            ;;
        *) _declare_var__parsing=1;
        esac
    done

    if [ "$#" -eq 0 ]; then
        printf "* ERROR: No variable name or assignment provided.\n" >&2
        printf "$help_content\n" >&2
        return 1
    fi
    
    while [ "$#" -gt 0 ] && [ "$_declare_var__exitcode" -eq 0 ]; do
        _declare_var__v="$1"; shift
        _declare_var__assign_value=""
        
        if printf "%s" "$_declare_var__v" | grep '=' >/dev/null; then
            _declare_var__varname="${_declare_var__v%%=*}"
            _declare_var__assign_value="${_declare_var__v#*=}"
        else
            _declare_var__varname="${_declare_var__v}"
            _declare_var__assign_value=""
        fi

        _declare_var__varname="$_declare_var__name_prefix$(printf "$_declare_var__name_pattern" "$_declare_var__varname")$_declare_var__name_suffix"
        [ ! -z "$_declare_var__name_transformation" ] && _declare_var__varname="$(printf "$_declare_var__varname" | $_declare_var__name_transformation)"
        _declare_var__value="$(eval "printf \"%s\" \"\$$_declare_var__varname\"")"
        
        # 
        # Detecting variable status
        #

        if [ ! -z "$_declare_var__testing_empty" ]; then
            _declare_var__is_empty="$([ -z "$_declare_var__value" ]; echo "$?")"
            [ "$_declare_var__is_empty" -ne 0 ] && _declare_var__is_empty=1
            [ "$_declare_var__is_empty" -eq 0 ] && _declare_var__is_defined=0
        else
            _declare_var__is_empty="$_declare_var__testing_empty"
        fi

        if [ ! -z "$_declare_var__testing_export" ]; then
            _declare_var__is_export="$(export -p | grep -E "^((readonly|declare|export).*\\s+)?$_declare_var__varname=" >/dev/null 2>/dev/null; echo "$?")"
            [ "$_declare_var__is_export" -ne 0 ] && _declare_var__is_export=1
            [ "$_declare_var__is_export" -eq 0 ] && _declare_var__is_defined=0
        else
            _declare_var__is_export="$_declare_var__testing_export"
        fi

        if [ ! -z "$_declare_var__testing_readonly" ]; then
            _declare_var__is_readonly="$(readonly -p | grep -E "^((readonly|declare|export).*\\s+)?$_declare_var__varname=" >/dev/null 2>/dev/null; echo "$?")"
            [ "$_declare_var__is_readonly" -ne 0 ] && _declare_var__is_readonly=1
            [ "$_declare_var__is_readonly" -eq 0 ] && _declare_var__is_defined=0
        else
            _declare_var__is_readonly="$_declare_var__testing_readonly"
        fi

        if [ -z "$_declare_var__is_defined" ]; then
            if [ ! -z "$_declare_var__testing_defined" ]; then
                _declare_var__is_defined="$(set | grep -E "^((readonly|declare|export).*\\s+)?$_declare_var__varname=" >/dev/null 2>/dev/null; echo "$?")"
            else
                _declare_var__is_defined="$_declare_var__testing_defined"
            fi
        fi

        if [ ! -z "$_declare_var__custom_tests" ]; then
            IFS="$_declare_var__custom_test_sep"
            for custom_test in $_declare_var__custom_tests; do
                _declare_var__is_custom_success="$("$custom_test" "$_declare_var__varname" >/dev/null 2>/dev/null; echo $?)"
                if [ "$_declare_var__is_custom_success" -ne 0 ]; then
                    break
                fi
            done
            unset IFS
        else
            _declare_var__is_custom_success=1
        fi

        # 
        # Determining _declare_var__is_success
        #

        _declare_var__is_success=1
        if [ "$_declare_var__test_mode" == "any" ]; then
            [ "$_declare_var__is_empty" = "$_declare_var__testing_empty" ] || \
                [ "$_declare_var__is_defined" = "$_declare_var__testing_defined" ] || \
                [ "$_declare_var__is_export" = "$_declare_var__testing_export" ] || \
                { [ -z "$_declare_var__custom_tests" ] || [ "$_declare_var__is_custom_success" -eq 0 ]; }
            _declare_var__is_success="$?"
        else
            [ "$_declare_var__is_empty" = "$_declare_var__testing_empty" ] && \
                [ "$_declare_var__is_defined" = "$_declare_var__testing_defined" ] && \
                [ "$_declare_var__is_export" = "$_declare_var__testing_export" ] && \
                { [ -z "$_declare_var__custom_tests" ] || [ "$_declare_var__is_custom_success" -eq 0 ]; }
            _declare_var__is_success="$?"
        fi

        [ "$_declare_var__is_success" -ne 0 ] && continue

        #
        # Guessing variable to assign
        #

        if [ -z "$_declare_var__assign_value" ]; then
            if [ "$_declare_var__is_defined" -ne 0 ]; then
                _declare_var__assign_value="$_declare_var__default_undef_value"
            elif [ -z "$_declare_var__value" ]; then
                _declare_var__assign_value="$_declare_var__default_value"
            else
                _declare_var__assign_value="$_declare_var__value"
            fi
        fi

        # At least some protection against scripting attacks:
        # - The first `printf` escapes newlines.
        # - The following `sed` escapes double-quotes, so that the string may
        #   not end prematurely (to prevent e.g. `a="b\"; rm -rf /; echo \""`
        #   from becoming `a="b"; rm -rf /; echo ""`)
        # But I guess this is not  enough. In fact, the `eval` approach is
        # already quite risky... Tread with care.
        [ ! -z "$_declare_var__assign_value" ] && _declare_var__assign_value="$(printf "%s" "$_declare_var__assign_value" | sed 's;";\\";g')"


        #
        # Creating action command
        #

        _declare_var__cmd=""
        case "$_declare_var__test_action" in
        assign)
            [ "$_declare_var__is_declaring_readonly" -eq 0 ] && _declare_var__cmd="readonly "
            _declare_var__cmd="${_declare_var__cmd}${_declare_var__varname}=\"${_declare_var__assign_value}\""
            [ "$_declare_var__is_declaring_export" -eq 0 ] && _declare_var__cmd="${_declare_var__cmd} ; export $_declare_var__varname"
            ;;
        name)
            [ "$_declare_var__is_success" -eq 0 ] && _declare_var__cmd="printf \"$_declare_var__varname\n\""
            ;;
        fail-name)
            [ "$_declare_var__is_success" -ne 0 ] && _declare_var__cmd="printf \"$_declare_var__varname\n\""
            ;;
        custom)
            _declare_var__name_kind=""
            if [ "$_declare_var__is_declaring_export" -eq 0 ]; then
                _declare_var__name_kind="export"
            else
                _declare_var__name_kind="global"
            fi
            if [ "$_declare_var__is_declaring_readonly" -eq 0 ]; then
                _declare_var__name_kind="$_declare_var__name_kind:readonly"
            else
                _declare_var__name_kind="$_declare_var__name_kind:rw"
            fi
            _declare_var__name_kind="$_declare_var__name_kind:string"

            _declare_var__cmd="$_declare_var__custom_action '$_declare_var__name_kind' \"$_declare_var__varname\" \"$_declare_var__assign_value\""
            ;;
        custom-prefix)
            _declare_var__cmd="$_declare_var__custom_action $_declare_var__varname=\"${_declare_var__assign_value}\""
            ;;
        *) echo "* ERROR: Something went wrong!"; return 1 ;;
        esac

        if [ "$_declare_var__is_dry_run" -eq 0 ]; then
            printf "%s\n" "$_declare_var__cmd"
        else
            eval "$_declare_var__cmd"
            _declare_var__exitcode="$?"
        fi
    done

    return "$_declare_var__exitcode"
}
