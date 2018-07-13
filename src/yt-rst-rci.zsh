#! /usr/bin/env zsh

SELF="${0##*/}"
. yt_prelude

zmodload -F zsh/stat b:zstat

function fx {
  local dir=$1
  local f=$2

  local date title furi
  declare -a fstat

  zstat -A fstat $f
  date=$(date -d@${fstat[10]} --rfc-3339=date)
  title=$(yt-rst-title $f)
  furi=${f%%.rst}.html
  furi=${furi##${dir}}

  printf -- '* `%s %s <%s>`_\n' $date $title $furi
}

if [[ $1 == "--one" ]]; then
  shift
  fx $@
else
  dir=$1
  set -x
  find $dir -name '*.rst' -print0 | xargs -0 -n1 $SELF --one $dir | sort -hr
fi
