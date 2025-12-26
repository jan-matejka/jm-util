#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

root=$(git rev-parse --show-toplevel) || fatal "failed to find work dir"

# opts
o_all=false
o_one_commit=false
o_msg=""
o_quiet=false

# parse args
declare -a pargs
declare -A paargs

zparseopts -K -D -a pargs -A paargs 1 a m: q
(( ${pargs[(I)-1]} )) && o_one_commit=true
(( ${pargs[(I)-a]} )) && o_all=true
(( ${pargs[(I)-q]} )) && set -- -q $@
(( ${${(k)paargs}[(I)-m]} )) && o_msg="${paargs[-m]}"

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
  o_one_commit=true
}

$o_one_commit && {
  lcpp=$(status | awk "$filter { print \$9 }" | jm-lcpp)
  [[ -n $o_msg ]] && lcpp+=": $o_msg"
  git -C $root commit $@ $commit_opts -m "$lcpp" </dev/tty
  (( $? > 0 )) && exit 255
  # override EDITOR to start it with cursor placed at the end of the commit message subject
  (( ${${(k)paargs}[(I)-m]} )) || EDITOR='vim -c "normal A"' git commit $@ --amend || exit 1
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
