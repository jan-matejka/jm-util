#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude
set -e -o pipefail

(( $# )) || exec git
cmd=$1; shift

if command -v gytr-$cmd >/dev/null; then
  exec gytr-$cmd $@
fi

exec git $cmd $@
