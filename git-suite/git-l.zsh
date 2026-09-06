#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude
set -e

declare -A paargs
zparseopts -K -D -E -A paargs S: G: h

args=( --oneline --decorate --graph )

has_opt -S && args+=( -S ${paargs[-S]} --no-graph )
has_opt -G && args+=( -G ${paargs[-G]} --no-graph )
# -h is extra option; not in vanilla git
has_opt -h && args+=( --pretty=format:"%H" --no-graph )

# cases:
# --grep <s>
# --grep <s> <rev-range>
# --grep <s> -- <path>
# -i <rev-range>
# general:
# --opt <arg>
# FIXME: There is no way to parse out rev-range while letting opts passthrough
# generically bc we don't know if <arg> is opt-val or narg.
if ! (( $# )); then
  def=$(git config get --default main init.defaultBranch )
  cur=$(git branch --show-current)
  if [[ $def != $cur ]]; then
    args+=( "${def}.." )
  fi
fi

exec git log $args $@
