{ # this ensures the entire script is downloaded #

mnm_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

mnm() {
  # 如果没有参数，打印一个help
  if [ "$#" -lt 1 ]; then
    mnm --help
    return
  fi

  local i
  for i in "$@"
  do
    case $i in
      --) break ;;
      '-h'|'help'|'--help')
        MNM_NO_COLORS=""
        for j in "$@"; do
          if [ "${j}" = '--no-colors' ]; then
            MNM_NO_COLORS="${j}"
            break
          fi
        done

        mnm_echo
        mnm_echo "Markdown Notes Manager"
        mnm_echo
        mnm_echo 'Usage:'
        mnm_echo '  mnm --help    显示帮助'
        mnm_echo '  mnm sync      同步笔记库'
        return 0;
      ;;
    esac
  done

  local COMMAND
  COMMAND="${1-}"
  shift

  case ${COMMAND} in
    "sync")
        mnm_echo "hello,sync"
    ;;
    *)
      >&2 mnm --help
      return 127
    ;;
  esac
}

} # this ensures the entire script is downloaded #