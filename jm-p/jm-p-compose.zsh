#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

test -n "${1:-}" || exec man jm-pc

test -e $SELF-$1 && exec jm_dispatch $SELF "$@"
exec podman compose $@
