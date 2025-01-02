Setup single::

  $ export HOME=$TMPDIR
  $ mkdir -p ~/git/ns/foo/master
  $ mkdir -p ~/git/ns/foo/master/a/b
  $ mkdir -p ~/git/ns/foo/master/c/d
  $ touch ~/git/ns/foo/master/c/d/foo
  $ touch ~/git/ns/foo/master/c/d/bar
  $ mkdir -p ~/git/ns/foo/wip
  $ mkdir ~/git/foo
  $ touch ~/git/foo/master

Test single::

  $ jm find-git foo/master
  /tmp/*/git/ns/foo/master (glob)

Setup single git dir::

  $ mkdir -p ~/git/ns2/foo/master
  $ mkdir ~/git/ns/foo/master/.git

Test single git dir::

  $ jm find-git foo/master
  /tmp/*/git/ns/foo/master (glob)

Setup single git file::

  $ rmdir ~/git/ns/foo/master/.git
  $ touch ~/git/ns/foo/master/.git

Test single git dir::

  $ jm find-git foo/master
  /tmp/*/git/ns/foo/master (glob)
