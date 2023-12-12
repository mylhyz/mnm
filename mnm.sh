{ # this ensures the entire script is downloaded #

mnm_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

mnm() {
  if [ "$#" -lt 1 ]; then
    mnm --help
    return
  fi
}

} # this ensures the entire script is downloaded #