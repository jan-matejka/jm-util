#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

dir="*$1"
shift
rs=( $(find $HOME/git -type d -path $dir) )
(( ${#rs} == 1 )) && {
  printf "%s\n" "$rs"
  exit 0
}

exit 1
