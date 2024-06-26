#!/bin/false
# vim: filetype=zsh

setopt no_unset
setopt pipe_fail
setopt warn_create_global

autoload -U zargs

function fatal {
  f-msg "$@"
  exit 1
}

function msg {
  local level=$1
  local msg=$2
  shift 2
  msg=$(printf $msg "$@")
  printf >&2 -- "%s: %s: %s\n" $SELF $level $msg
}

function f-msg {
  msg fatal "$@"
}

function warning {
  msg warning "$@"
}

function f-already-exists {
  fatal "%s %s already exists" "$@"
}

function f-git-initialized {
  fatal "%s already initialized" "$1"
}

function f-not-executable {
  fatal "%s %s not executable" "$@"
}

function f-not-regular {
  fatal "%s %s exist but is not a regular file" "$@"
}

function f-symlink {
  fatal "%s %s is symlink" "$@"
}

function check-arg {
  test -n "${2:-}" || fatal "missing argument %s" $1
}

function check-executable {
  type "$1" >/dev/null 2>&1 || fatal "cannot execute %s" $1
}

function redir {
  declare -A args=( -0 0 -1 1 -2 2 )
  zparseopts -K -D -A args 0: 1: 2:
  "$@" <&${args[-0]} 1>&${args[-1]} 2>&${args[-2]}
}

${JM_XTRACE:-false} && set -x
