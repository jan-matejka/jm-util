#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude
set -e

declare -A paargs
zparseopts -K -D -E -A paargs S: G:

args=( --oneline --decorate --graph )

has_opt -S && args+=( -S ${paargs[-S]} --no-graph )
has_opt -G && args+=( -G ${paargs[-G]} --no-graph )

exec git log $args
