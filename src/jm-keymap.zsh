#! /usr/bin/env zsh

SELF="${0##*/}"
. yt_prelude

test -n "${1:-}" || exec man yt-keymap
exec yt_dispatch $SELF "$@"
