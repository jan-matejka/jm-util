#! /usr/bin/env zsh

SELF="${0##*/}"
. yt_prelude

root=$(git rev-parse --show-toplevel) || fatal "failed to find work dir"

git -C $root status --porcelain=v2 | \
  awk '/^1/ { print $9; }' | \
  xargs -n1 -r yt cif1 $@ $root
