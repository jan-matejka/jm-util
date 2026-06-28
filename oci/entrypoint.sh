#! /usr/bin/env sh

set -xeu

[ "${FIXUP_GIT_DIRS:-false}" = "true" ] && {
  home=/home/user
  master=$home/master
  wip=$home/src

  echo "gitdir: $master/.git/worktrees/wip" >$wip/.git
  echo "$home/src/.git" >$master/.git/worktrees/wip/gitdir
}

exec "$@"
