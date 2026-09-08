#!/usr/bin/env zsh
# jm-toml-get <key> [<default>]
#
# Reads <key> -- a dotted TOML path, e.g. tool.jmutil.claude.account -- from
# <repo-root>/project.toml or <repo-root>/pyproject.toml, whichever exists
# and has it first. A trailing [] on <key> reads an array, one element per
# output line (yq's own array-iteration syntax).
#
# Exits 0 and prints the value if <key> is present; exits 1 otherwise,
# printing <default> first if one was given.

SELF="${0##*/}"
. jm_prelude

set -eu

key=${1:?}; shift

if (( $# )); then
  default=${1:-}; shift
fi

root=$(git rev-parse --show-toplevel 2>/dev/null || true)
[[ -n $root ]] || fatal "not a git repository"

if (( ${+JM_UTIL_YQ} )); then
  command -v ${JM_UTIL_YQ} >/dev/null
fi

if (( ! ${+JM_UTIL_YQ} )); then
  for yq in yq-go yq; do
    command -v $yq >/dev/null && { JM_UTIL_YQ=$yq; break } || {
      warning "command not found: $yq"
    }
  done

  if (( ! ${+JM_UTIL_YQ} )); then
    (( ${+default} )) && { print -r -- $default; exit 0 }
    fatal "no yq"
  fi
fi

base=${key%\[\]}
[[ $base == *.* ]] && parent=${base%.*} || parent=
leaf=${base##*.}

candidates=( $root/project.toml $root/pyproject.toml )
for f in $candidates; do
  [[ -f $f ]] || continue
  present=$($JM_UTIL_YQ -p toml -o toml ".${parent} | has(\"$leaf\")" "$f") || present=false
  if [[ $present == true ]]; then
    $JM_UTIL_YQ -p toml -o toml ".$key" "$f"
    exit 0
  fi
done

(( ${+default} )) && {
  print -r -- "$default"
  exit 0
}

exit 1
