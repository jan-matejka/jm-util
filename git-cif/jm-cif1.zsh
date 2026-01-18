#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

# opts
o_wip=false
o_msg=""
o_no_edit=false
o_quiet=false

# parse args
declare -a pargs
declare -A paargs
zparseopts -K -D -a pargs w m: -no-edit q
(( ${pargs[(I)-w]} )) && o_wip=true
(( ${pargs[(I)--no-edit]} )) && o_no_edit=true
(( ${pargs[(I)-q]} )) && o_quiet=true
(( ${${(k)paargs}[(I)-m]} )) && o_msg="${paargs[-m]}"

# operands
# file_status is the XY field of `git status --porcelain=v2`, see git-cif implementation
git_path=${1:?}
file_status=${2:?}
file=${3:?}

# prefix message with "wip: " if -w was used, otherwise no prefix
$o_wip && msg="wip: " || msg=""

# add the file into message

{ [[ -z $o_msg ]] && ! $o_no_edit } && {
  msg+="$file:"
  [[ -n $o_msg ]] && msg+="$o_msg"

  # prefix message with "add " if file_status indicates
  test ${file_status:0:1} = A && o_msg+=":add"

  g_args=( -e -m $msg )
} || {
  msg+="$file"
  g_args=( "-m" $msg )
}

$o_quiet && g_args+=( -q )

# override EDITOR to start it with cursor placed at the end of the commit message subject
EDITOR='vim -c "normal A"' git -C $git_path commit $g_args $file </dev/tty
(( $? > 0 )) && exit 255
exit 0
