#! /usr/bin/env sh

set -xeu

home=/home/user
master=$home/master
wip=$home/src

echo "gitdir: $master/.git/worktrees/wip" >$wip/.git
echo "gitdir: $master/.git" >$master/.git/worktrees/wip/gitdir

exec "$@"
