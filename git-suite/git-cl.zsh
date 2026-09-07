#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude
set -e -o pipefail

url=${1:?}; shift
(( $# )) && { dir=$1 ;shift } || dir=${GIT_ORG_HOME:=~/git}
opts=()
[[ ${dir:0:1} == '/' ]] || opts=( --relative-to=$PWD )
dir=$(realpath -mL $dir $opts )

case $url in
http://*)
  warning 'unsecure transport'
  ;&
https://*)
  if [[ $url =~ "^(.+)://([^/]+)/(.+)$" ]]; then
    scheme=${match[1]}
    host=${match[2]}
    path_=${match[3]}
  fi
  ;;
*:*.git)
  # FIXME: will match scheme://
  if [[ $url =~ "^([^:]+):(.+)$" ]]; then
    host=${match[1]}
    path_=${match[2]}
  fi
  ;;
*)
  fatal "Invalid url=${url}"
esac

if [[ $path_ =~ "^([^/]+)/([^/]+)$" ]]; then
  org=${match[1]}
  name=${match[2]}
  repo=${name%.git}
else
  fatal "Invalid path=${path_}"
fi

_parse_ref_name() {
  # echo 'ref: refs/heads/main    HEAD' |
  awk '$1 == "ref:" && $2 ~ "refs/heads/*" { sub("^refs/heads/", "", $2); print $2 } '
}

head=$(git ls-remote --exit-code --symref "$url" HEAD | _parse_ref_name)

git clone --separate-git-dir ${dir}/${org}/${repo}/${repo}.git $url ${dir}/${org}/${repo}/${head}
