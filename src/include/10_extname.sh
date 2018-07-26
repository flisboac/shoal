
extname() {
    local arg
    local filename
    local extension
    local help_content
    local printing_zero; printing_zero=1
    local printing_name; printing_name=1
    local parsing; parsing=0
    local dot; dot="."
    local name_sep; name_sep="\t"
    local prefix

{ help_content="$(cat)"; } <<"HELP"
Prints the extension (including the dot) for each PATHNAME (a dirname or filename).
Usage:
  $ extname [OPTIONS] <PATHNAME>...
Where OPTIONS is in:
  -z, --zero         : Output NUL instead of newline for each PATHNAME
  -D, --no-dot       : Do not output a dot at the beginning of each extension
  -n, --print-name   : Prints the name before its extension
  -s, --name-sep=SEP : Specifies the input-name/extension separator
      --             : Ends option processing
  -h, --help         : Prints this help content
HELP

    [ "$#" -eq 0 ] && printf "* ERROR: Missing pathname. Type \`extname --help\` for more information.\n" >&2 && return 1

    while [ "$#" -gt 0 ] && [ "$parsing" -eq 0 ]; do
        case "$1" in
        -h|--help) printf "$help_content\n" >&2; return 0 ;;
        -z|--zero) printing_zero=0; shift ;;
        -D|--no-dot) dot=""; shift ;;
        -n|--print-name) printing_name=0; shift ;;
        -s|--name-sep) shift; name_sep="$1"; shift ;;
        -s*) name_sep="$( echo "$1" | sed 's;^-s;;')"; shift ;;
        --name-sep=*) name_sep="$( echo "$1" | sed 's;^[^=]*=;;')"; shift ;;
        --) parsing=1; shift ;;
        -*) printf "* ERROR: Unknown option '$1'.\n" >&2; return 1 ;;
        *) parsing=1 ;;
        esac
    done

    while [ "$#" -gt 0 ]; do
        arg="$1"; shift
        filename="$(basename -- "$arg")" || return "$?"
        extension="${filename##*.}"

        prefix=""
        [ "$printing_name" -eq 0 ] && prefix="$arg$name_sep"

        if [ "$printing_zero" -eq 0 ]; then
            printf "$prefix$dot$extension\0"
        else
            printf "$prefix$dot$extension\n"
        fi
    done
}
