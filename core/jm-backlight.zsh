#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

dir="/sys/class/backlight/intel_backlight"

declare -a pargs
zparseopts -K -D -a pargs -max

test -n "${1:-}" && {
  echo $1 > $dir/brightness
  return 0
}

(( ${pargs[(I)--max]} )) && exec cat $dir/max_brightness
exec cat $dir/actual_brightness
