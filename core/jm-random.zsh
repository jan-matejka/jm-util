#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

size=${1:?}
shift

dd status=none if=/dev/urandom bs=$size count=1 |
  base64 |
  tr -d '\n' |
  head -c $size
