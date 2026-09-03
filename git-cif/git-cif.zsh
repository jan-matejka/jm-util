#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude
set -e

root=$(git rev-parse --show-toplevel) || fatal "failed to find work dir"

# opts
o_all=false
o_msg=""
o_quiet=false
o_discrete=false

# parse args
declare -a pargs
declare -A paargs

zparseopts -K -D -a pargs -A paargs a m: q d
(( ${pargs[(I)-a]} )) && o_all=true
(( ${pargs[(I)-d]} )) && o_discrete=true
(( ${pargs[(I)-q]} )) && set -- -q $@
(( ${${(k)paargs}[(I)-m]} )) && o_msg="${paargs[-m]}"

# FIXME: these should be in file config that can be committed.
c_lcpp_trim_file_name=$(git config get --default false jmutil.gitcif.lcpp-trim-file-name)
c_lcpp_trim_file_ext=$(git config get --default true jmutil.gitcif.lcpp-trim-file-ext)

status() {
  git -C $root status --porcelain=v2
}

$o_all && {
  # match all changes except to untracked or ignored files
  filter='$1 ~ "1|2"'
  commit_opts=( -a )
} || {
  # match any change in index
  filter='$1 ~ "1|2" && $2 ~ "[^.]."'
  commit_opts=( )
}

! $o_discrete && {
  lcpp=$(status | awk "$filter { print \$9 }" | jm-lcpp)

  # apply configured scope-rewrite rules (sed s/// expressions), in the
  # order they appear in git config, e.g.:
  #   git config set --local --append jmutil.gitcif.scope-rewrite 's/^foo\/src\//foo\//'
  local -a scope_rewrite_rules sed_args
  scope_rewrite_rules=(${(f)"$(git -C $root config get --all jmutil.gitcif.scope-rewrite || true)"})
  (( ${#scope_rewrite_rules} )) && {
    sed_args=()
    for r in "${scope_rewrite_rules[@]}"; do
      sed_args+=(-e "$r")
    done
    lcpp=$(print -r -- "$lcpp" | sed "${sed_args[@]}")
  }

  [[ -n $o_msg ]] && lcpp+=": $o_msg"

  # open EDITOR only if -m is not given
  (( ${${(k)paargs}[(I)-m]} )) || commit_opts+=( --edit )

  # override EDITOR to start it with cursor placed at the end of the commit message subject
  [[ ${${EDITOR:-}[1,3]} = "vim" ]] && export EDITOR='vim -c "normal A"'

  # Passing the default message into git via stdin is messing with running
  # editor so that is not an option.

  if $c_lcpp_trim_file_name && test -f $lcpp && [[ $lcpp == */* ]]; then
    lcpp=${lcpp%/*}
  elif $c_lcpp_trim_file_ext && test -f $lcpp && [[ $lcpp == *.* ]]; then
    lcpp=${lcpp%.*}
  fi

  git -C $root commit $@ $commit_opts -m "$lcpp"
  (( $? > 0 )) && exit 255
  exit 0
} || {
  # For the output of status porcelain refer to dram/99-ref-git-status-porcelain-v2.rst in addition to
  # the git-status(1)
  (( ${${(k)paargs}[(I)-m]} )) && {
    [[ -n $o_msg ]] && set -- $@ -m "$o_msg" || set -- $@ --no-edit
  }
  status | \
    awk "$filter { print \$2 \" \" \$9; }" | \
    xargs -n2 -r jm cif1 $@ $root
}
