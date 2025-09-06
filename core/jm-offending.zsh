#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

check-arg "lineno" ${1:-}
lineno=$(( $1 + 0 )) # type cast to int
exec sed -i "${lineno}d" $HOME/.ssh/known_hosts
