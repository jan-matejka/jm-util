#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude
set -e

declare -A paargs
zparseopts -K -D -E -A paargs S:

args=( --oneline --decorate --graph )

has_opt -S && args+=( -S ${paargs[-S]} --no-graph )

exec git log $args
