setup podman::

  $ mkdir $TMPDIR/bin
  $ export PATH="$TMPDIR/bin:$PATH"
  $ cat >$TMPDIR/bin/podman <<EOF
  > #!/bin/sh
  > echo "\$0 \$@"
  > EOF
  $ chmod +x $TMPDIR/bin/podman

setup git::

  $ git init -q master
  $ cd master
  $ git config --local user.name Foo
  $ git config --local user.email foo@example.com
  $ export GIT_COMMITTER_DATE='1970-01-01T00:00:00'
  $ export GIT_AUTHOR_DATE='1970-01-01T00:00:00'
  $ touch a; git add a; git commit -qam 'init'

not a git worktree::

  $ pc foo
  /tmp/.*/podman compose foo (re)

worktree::

  $ git worktree add -q ../wip
  $ cd ../wip
  $ cat .git
  gitdir: /tmp/dramtests-.* (re)

  $ pc foo
  /tmp/.*/podman compose foo (re)
  $ cat .git
  gitdir: ../master/.git/worktrees/wip

worktree relativization is idempotent::

  $ pc foo
  /tmp/.*/podman compose foo (re)
  $ cat .git
  gitdir: ../master/.git/worktrees/wip

TAG export on master::

  $ cd ../master
  $ jm-container-env-setup env | grep TAG
  TAG=latest

TAG export on main::

  $ git worktree add -q ../main
  $ cd ../main
  $ jm-container-env-setup env | grep TAG
  TAG=latest

TAG export on any other arbitrary branch::

  $ git worktree add -q ../any
  $ cd ../any
  $ jm-container-env-setup env | grep TAG
  TAG=any
