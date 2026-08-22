#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

set -eu

root=$(git rev-parse --show-toplevel)
dotgit=$root/.git

function worktree_make_relative {
  [[ -f $dotgit ]] || return 0

  local gitdir=$(grep '^gitdir: ' $dotgit | head -n1 | sed 's/gitdir: //')
  if [[ ${gitdir[1]} == '/' ]]; then
    local relgitdir=$(realpath --relative-to $root $gitdir)
    sed -i "s#^gitdir: .*\$#gitdir: $relgitdir#" $dotgit
  fi
}

function export_tag {
  [[ -z ${TAG:-} ]] || return 0
  local b=$(git branch --show-current)
  declare -g TAG=latest
  if [[ $b != "master" ]] && [[ $b != "main" ]]; then
    TAG=$b
  fi
  export TAG
}

worktree_make_relative
export_tag

exec $@
