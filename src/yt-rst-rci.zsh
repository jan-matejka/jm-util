#! /usr/bin/env zsh

SELF="${0##*/}"
. yt_prelude

zmodload -F zsh/stat b:zstat

function fx {
  local f=$1
  local date
  local title
  declare -a fstat

  zstat -A fstat $f
  date=$(date -d@${fstat[10]} --rfc-3339=date)
  title=$(yt-rst-title $f)

  printf -- "* %s %s\n" $date $title
}

zargs -n1 -- $@ -- fx
