#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

test -n "${1:-}" || exec man jm-keymap
exec jm_dispatch $SELF "$@"
