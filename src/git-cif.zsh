#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

root=$(git rev-parse --show-toplevel) || fatal "failed to find work dir"

# opts
o_all=false
o_edit=false

# parse args
declare -a pargs
zparseopts -K -D -a pargs a e
(( ${pargs[(I)-a]} )) && o_all=true
(( ${pargs[(I)-e]} )) && o_edit=true

status() {
  git -C $root status --porcelain=v2
}

$o_all && {
  lcpp=$(status | \
    awk 'NF==9 { print $9; }' | jm-lcpp)
  lcpp+=": "
  git -C $root commit -a -m "$lcpp" </dev/tty
  (( $? > 0 )) && exit 255
  # override EDITOR to start it with cursor placed at the end of the commit message subject
  $o_edit && { EDITOR='vim -c "normal A"' git commit --amend || exit 1 }
  exit 0
} || {
  $o_edit && e_arg=-e || e_arg=""
  # For the output of status porcelain refer to dram/99-ref-git-status-porcelain-v2.rst in addition to
  # the git-status(1)
  status | \
    awk '/^1/ { print $2 " " $9; }' | \
    xargs -n2 -r jm cif1 $e_arg $@ $root
}
