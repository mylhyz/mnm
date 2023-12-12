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

install_mnm_from_git() {
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
}

mnm_do_install

} # this ensures the entire script is downloaded #