#! /usr/bin/env zsh

SELF="${0##*/}"
. yt_prelude

root=$(git rev-parse --show-toplevel) || fatal "failed to find work dir"

# For the output of status porcelain refer to dram/99-ref-git-status-porcelain-v2.rst in addition to
# the git-status(1)
git -C $root status --porcelain=v2 | \
  awk '/^1/ { print $2 " " $9; }' | \
  xargs -n2 -r yt cif1 $@ $root
