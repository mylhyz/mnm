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
        # 判断当前仓库是否是一个git仓库，不是的话报错返回 -1
        if [ -d .git ]; then
          mnm_echo "=> 当前目录为Git仓库"
        else
          mnm_echo "=> 当前目录并非Git仓库 !"
          return 1
        fi
        # 判断当前仓库是否有未保存的修改，是的话保存并提交 -2
        git_status=$(git status --porcelain)
        if [ -z "$git_status" ]; then
          mnm_echo "=> 当前Git仓库没有未保存的数据"
        else
          mnm_echo "=> 当前Git仓库有未保存的数据 !"
          command printf '\r=> '
          command git add . || {
            mnm_echo >&2 'git add . 命令失败'
            return 2
          }
          command printf '\r=> '
          command git commit -m "$(date)" || {
            mnm_echo >&2 "git commit 命令失败"
            return 2
          }
        fi
        # 拉取远程仓库最新数据 -3
        command printf '\r=> '
        command git pull --rebase || {
          mnm_echo >&2 'git pull --rebase 命令失败'
          return 3
        }
        # 推送到远程仓库 -4
        command printf '\r=> '
        command git push || {
          mnm_echo >&2 'git push 命令失败'
          return 4
        }
    ;;
    *)
      >&2 mnm --help
      return 127
    ;;
  esac
}

} # this ensures the entire script is downloaded #