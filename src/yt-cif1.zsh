#! /usr/bin/env zsh

SELF="${0##*/}"
. yt_prelude

# opts
o_edit=false

# parse args
declare -a pargs
zparseopts -K -D -a pargs e
(( ${pargs[(I)-e]} )) && o_edit=true

git_path=${1:?}
file=${2:?}

msg="$file"

$o_edit && {
  t=$(mktemp)
  trap "rm $t" EXIT
  printf >$t -- "$msg: "
  g_args=( -t $t )
} || {
  g_args=( "-m" $msg )
}

# override EDITOR to start it with cursor placed at the end of the commit message subject
EDITOR='vim -c "normal A"' git -C $git_path commit $g_args $file </dev/tty
(( $? > 0 )) && exit 255
exit 0
