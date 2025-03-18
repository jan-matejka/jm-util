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

function f-out-var-conflicts-with-local {
  fatal 'ValueError: out_p_id=`%s` is local variable in %s\n' $@ ${funcstack[-1]}
}

function gh-project-id {
  # TBD: remove evals
  local out_p_id=$1
  shift
  local out_p_no=$1
  shift
  local out_argv=$1
  shift

  local _p_no pls_args _p_id p_title pargs paargs i
  local -a pls_args pargs
  local -A paargs

  (( $(local $out_p_id | wc -l) == 1 )) && {
    f-out-var-conflicts-with-local $out_p_id
    return 1
  }

  (( $(local $out_p_no | wc -l) == 1 )) && {
    f-out-var-conflicts-with-local $out_p_no
    return 1
  }

  (( $(local $out_argv | wc -l) == 1 )) && {
    f-out-var-conflicts-with-local $out_argv
    return 1
  }

  zparseopts -K -D -Apaargs p:
  typeset -g $out_argv
  eval "$out_argv=(${argv[@]})"

  typeset -g $out_p_no
  [[ -n ${paargs[-p]:-} ]] && {
    _p_no=${paargs[-p]}
  } || {
    gh project list
    printf "Select project number: "
    read _p_no
  }
  eval $out_p_no=$_p_no

  pls_args=(
    --format json
    --jq '.projects[] | select(.number == 1) | .id, .title'
  )

  { gh project list $pls_args; echo \0 } | read -d \0 _p_id p_title
  typeset -g $out_p_id=$_p_id

  printf "Selected: %s\n" $p_title
  for i in {3..1}; do
    printf "waiting %ss\n" $i
    sleep 1s
  done
}

${JM_XTRACE:-false} && set -x
