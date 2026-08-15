setup::

  $ TMPBINDIR=$TMPDIR/bin
  $ mkdir $TMPBINDIR

call by relative path::

  $ ln -snf $TESTDIR/../build/bin/jm-alias $TMPBINDIR/grr
  $ ../tmp/bin/grr foo
  [1]

  $ export PATH="$TMPBINDIR:$PATH"

test unknown alias::

  $ ln -snf $TESTDIR/../build/bin/jm-alias $TMPBINDIR/foo
  $ foo
  jm-alias: foo: alias not found
  [1]

test not found::

  $ ln -snf $TESTDIR/../build/bin/jm-alias $TMPBINDIR/pc
  $ pc
  jm-alias: podman: command not found
  [1]

test ok::

  $ ln -snf /bin/true $TMPBINDIR/podman
  $ pc

test additional argv::

  $ mkdir foo
  $ echo bar >> foo/bar
  $ grr bar
  foo/bar:bar

test alias list::

  $ jm-alias
  b
  d
  dc
  dpc
  g
  gr
  gr_pics
  gr_video
  grr
  j
  l
  ll
  p
  pc
  s
  t
