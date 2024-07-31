#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #

mnm_has() {
  type "$1" > /dev/null 2>&1
}

mnm_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

if [ -z "${BASH_VERSION}" ] || [ -n "${ZSH_VERSION}" ]; then
  # shellcheck disable=SC2016
  mnm_echo >&2 'Error: the install instructions explicitly say to pipe the install script to `bash`; please follow them'
  exit 1
fi

mnm_default_install_dir() {
  [ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.mnm" || printf %s "${XDG_CONFIG_HOME}/mnm"
}

mnm_install_dir() {
  if [ -n "$MNM_DIR" ]; then
    printf %s "${MNM_DIR}"
  else
    mnm_default_install_dir
  fi
}

mnm_latest_version() {
  mnm_echo "v0.0.1"
}

mnm_source() {
  mnm_echo "https://github.com/mylhyz/mnm.git"
}

mnm_try_profile() {
  if [ -z "${1-}" ] || [ ! -f "${1}" ]; then
    return 1
  fi
  mnm_echo "${1}"
}

mnm_detect_profile() {
  if [ "${PROFILE-}" = '/dev/null' ]; then
    # the user has specifically requested NOT to have mnm touch their profile
    return
  fi

  if [ -n "${PROFILE}" ] && [ -f "${PROFILE}" ]; then
    mnm_echo "${PROFILE}"
    return
  fi

  local DETECTED_PROFILE
  DETECTED_PROFILE=''

  if [ "${SHELL#*bash}" != "$SHELL" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      DETECTED_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      DETECTED_PROFILE="$HOME/.bash_profile"
    fi
  elif [ "${SHELL#*zsh}" != "$SHELL" ]; then
    if [ -f "$HOME/.zshrc" ]; then
      DETECTED_PROFILE="$HOME/.zshrc"
    elif [ -f "$HOME/.zprofile" ]; then
      DETECTED_PROFILE="$HOME/.zprofile"
    fi
  fi

  if [ -z "$DETECTED_PROFILE" ]; then
    for EACH_PROFILE in ".profile" ".bashrc" ".bash_profile" ".zprofile" ".zshrc"
    do
      if DETECTED_PROFILE="$(mnm_try_profile "${HOME}/${EACH_PROFILE}")"; then
        break
      fi
    done
  fi

  if [ -n "$DETECTED_PROFILE" ]; then
    mnm_echo "$DETECTED_PROFILE"
  fi
}

mnm_profile_is_bash_or_zsh() {
  local TEST_PROFILE
  TEST_PROFILE="${1-}"
  case "${TEST_PROFILE-}" in
    *"/.bashrc" | *"/.bash_profile" | *"/.zshrc" | *"/.zprofile")
      return
    ;;
    *)
      return 1
    ;;
  esac
}

install_mnm_from_git() {
  # 检查本地目录是否存在
  local INSTALL_DIR
  INSTALL_DIR="$(mnm_install_dir)"
  local MNM_VERSION
  MNM_VERSION="${MNM_INSTALL_VERSION:-$(mnm_latest_version)}"

  local fetch_error
  if [ -d "$INSTALL_DIR/.git" ]; then
    # Updating repo
    mnm_echo "=> mnm is already installed in $INSTALL_DIR, trying to update using git"
    command printf '\r=> '
    fetch_error="Failed to update mnm with $MNM_VERSION, run 'git fetch' in $INSTALL_DIR yourself."
  else
    fetch_error="Failed to fetch origin with $MNM_VERSION. Please report this!"
    mnm_echo "=> Downloading mnm from git to '$INSTALL_DIR'"
    command printf '\r=> '
    mkdir -p "${INSTALL_DIR}"
    if [ "$(ls -A "${INSTALL_DIR}")" ]; then
      # Initializing repo
      command git init "${INSTALL_DIR}" || {
        mnm_echo >&2 'Failed to initialize mnm repo. Please report this!'
        exit 2
      }
      command git --git-dir="${INSTALL_DIR}/.git" remote add origin "$(mnm_source)" 2> /dev/null \
        || command git --git-dir="${INSTALL_DIR}/.git" remote set-url origin "$(mnm_source)" || {
        mnm_echo >&2 'Failed to add remote "origin" (or set the URL). Please report this!'
        exit 2
      }
    else
      # Cloning repo
      command git clone "$(mnm_source)" --depth=1 "${INSTALL_DIR}" || {
        mnm_echo >&2 'Failed to clone mnm repo. Please report this!'
        exit 2
      }
    fi
  fi

  # 检出远程仓库到本地目录
  # Try to fetch tag
  if command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" fetch origin tag "$MNM_VERSION" --depth=1 2>/dev/null; then
    :
  # Fetch given version
  elif ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" fetch origin "$MNM_VERSION" --depth=1; then
    nvm_echo >&2 "$fetch_error"
    exit 1
  fi

  command git -c advice.detachedHead=false --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" checkout -f --quiet main || {
    mnm_echo >&2 "Failed to checkout the given version $MNM_VERSION. Please report this!"
    exit 2
  }
  if [ -n "$(command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" show-ref refs/heads/main)" ]; then
    if command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet 2>/dev/null; then
      command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet -D main >/dev/null 2>&1
    else
      mnm_echo >&2 "Your version of git is out of date. Please update it!"
      command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch -D main >/dev/null 2>&1
    fi
  fi

  # 使用 git pull --rebase 更新
  command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" pull --rebase --quiet origin main || {
    tms_echo >&2 "Failed to pull the given version $TMS_VERSION. Please report this!"
    exit 2
  }

  # 清理仓库
  mnm_echo "=> Compressing and cleaning up git repository"
  if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" reflog expire --expire=now --all; then
    mnm_echo >&2 "Your version of git is out of date. Please update it!"
  fi
  if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" gc --auto --aggressive --prune=now ; then
    mnm_echo >&2 "Your version of git is out of date. Please update it!"
  fi
  return
}

mnm_do_install() {
    # 创建本地路径
    if [ -n "${MNM_DIR-}" ] && ! [ -d "${MNM_DIR}" ]; then
        if [ -e "${MNM_DIR}" ]; then
            mnm_echo >&2 "File \"${MNM_DIR}\" has the same name as installation directory."
            exit 1
        fi

        if [ "${MNM_DIR}" = "$(mnm_default_install_dir)" ]; then
            mkdir "${MNM_DIR}"
        else
            mnm_echo >&2 "You have \$MNM_DIR set to \"${MNM_DIR}\", but that directory does not exist. Check your profile files and environment."
            exit 1
        fi
    fi

    if mnm_has git; then
      install_mnm_from_git
    else
      mnm_echo >&2 'You need git to install mnm'
      exit 1
    fi


    mnm_echo

    local MNM_PROFILE
    MNM_PROFILE="$(mnm_detect_profile)"
    local PROFILE_INSTALL_DIR
    PROFILE_INSTALL_DIR="$(mnm_install_dir | command sed "s:^$HOME:\$HOME:")"

    SOURCE_STR="\\nexport MNM_DIR=\"${PROFILE_INSTALL_DIR}\"\\n[ -s \"\$MNM_DIR/mnm.sh\" ] && \\. \"\$MNM_DIR/mnm.sh\"  # This loads mnm\\n"

    # shellcheck disable=SC2016
    COMPLETION_STR='[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads mnm bash_completion\n'
    BASH_OR_ZSH=false

    if [ -z "${MNM_PROFILE-}" ] ; then
      local TRIED_PROFILE
      if [ -n "${PROFILE}" ]; then
        TRIED_PROFILE="${MNM_PROFILE} (as defined in \$PROFILE), "
      fi
      mnm_echo "=> Profile not found. Tried ${TRIED_PROFILE-}~/.bashrc, ~/.bash_profile, ~/.zprofile, ~/.zshrc, and ~/.profile."
      mnm_echo "=> Create one of them and run this script again"
      mnm_echo "   OR"
      mnm_echo "=> Append the following lines to the correct file yourself:"
      command printf "${SOURCE_STR}"
      mnm_echo
    else
      if mnm_profile_is_bash_or_zsh "${MNM_PROFILE-}"; then
        BASH_OR_ZSH=true
      fi
      if ! command grep -qc '/mnm.sh' "$MNM_PROFILE"; then
        mnm_echo "=> Appending mnm source string to $MNM_PROFILE"
        command printf "${SOURCE_STR}" >> "$MNM_PROFILE"
      else
        mnm_echo "=> mnm source string already in ${MNM_PROFILE}"
      fi
    fi

    # Source mnm
    # shellcheck source=/dev/null
    \. "$(mnm_install_dir)/mnm.sh"

    mnm_reset

    mnm_echo "=> Close and reopen your terminal to start using mnm or run the following to use it now:"
    command printf "${SOURCE_STR}"
    if ${BASH_OR_ZSH} ; then
      command printf "${COMPLETION_STR}"
    fi
}

mnm_reset() {
  unset -f mnm_has mnm_install_dir mnm_latest_version mnm_profile_is_bash_or_zsh \
    mnm_source install_mnm_from_git \
    mnm_try_profile mnm_detect_profile \
    mnm_do_install mnm_reset mnm_default_install_dir
}

mnm_do_install

} # this ensures the entire script is downloaded #