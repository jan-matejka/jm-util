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

cur=$(git branch --show-current)
ref="refs/heads/$cur"
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
  if [[ $def != $cur ]]; then
    # include the tip of $def for context
    args+=( "${def}~1.." )
    # FIXME: ~1 may not exist
  fi
fi

# -h just wants a clean, scriptable hash list; leave it alone.
if has_opt -h; then
  exec git log $args $@
fi

args+=( --no-abbrev-commit )
[[ -t 1 ]] && args+=( --color=always )

git log --color=auto $args $@ \
  | git name-rev --annotate-stdin --name-only --refs $ref --always
