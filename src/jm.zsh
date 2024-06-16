#! /usr/bin/env zsh

SELF="${0##*/}"
. yt_prelude

declare -a pargs
declare -A paargs
zparseopts -K -D -a pargs -Apaargs x
(( ${pargs[(I)-x]} )) && {
  set -x
  export YT_XTRACE=true
}

xdgenv-exec YT yac-tools -- yt_dispatch $SELF "$@"
