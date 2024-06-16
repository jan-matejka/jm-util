#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

declare -a pargs
declare -A paargs
zparseopts -K -D -a pargs -Apaargs x
(( ${pargs[(I)-x]} )) && {
  set -x
  export JM_XTRACE=true
}

xdgenv-exec JM jm-util -- jm_dispatch $SELF "$@"
