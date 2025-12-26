#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

# opts
o_edit=false
o_wip=false

# parse args
declare -a pargs
zparseopts -K -D -a pargs e w
(( ${pargs[(I)-e]} )) && o_edit=true
(( ${pargs[(I)-w]} )) && o_wip=true

# operands
# file_status is the XY field of `git status --porcelain=v2`, see git-cif implementation
git_path=${1:?}
file_status=${2:?}
file=${3:?}

# prefix message with "wip: " if -w was used, otherwise no prefix
$o_wip && msg="wip: " || msg=""

# prefix message with "add " if file_status indicates
test ${file_status:0:1} = A && msg+="add "

# add the file into message
msg+="$file"

$o_edit && {
  t=$(mktemp)
  trap "rm $t" EXIT
  printf >$t -- "$msg: "
  g_args=( -e -F $t )
} || {
  g_args=( "-m" $msg )
}

# override EDITOR to start it with cursor placed at the end of the commit message subject
EDITOR='vim -c "normal A"' git -C $git_path commit $g_args $file </dev/tty
(( $? > 0 )) && exit 255
exit 0
