# Common shell utilities.

report_fatal_error() {
  local line
  for line in "$@"; do
    echo "$line" 1>&2
  done
  exit 1
}

# Prints its second or third argument depending on its first argument:
#
#     if_then_else "boolean" "if true" "if false"
#
if_then_else() {
  case "$1" in
  1|true|yes)
    echo "$2"
    ;;
  0|false|no)
    echo "$3"
    ;;
  *)
    report_fatal_error "Unexpected boolean value: $1"
  esac
}
