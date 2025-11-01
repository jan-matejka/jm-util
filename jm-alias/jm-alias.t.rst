setup::

  $ TMPBINDIR=$TMPDIR/bin
  $ export PATH="$TMPBINDIR:$PATH"
  $ mkdir $TMPBINDIR

test unknown alias::

  $ ln -snf $TESTDIR/../build/bin/jm-alias $TMPBINDIR/foo
  $ foo
  jm-alias: foo: alias not found
  [1]

test not found::

  $ ln -snf $TESTDIR/../build/bin/jm-alias $TMPBINDIR/pc
  $ pc
  jm-alias: podman-compose: command not found
  [1]

test ok::

  $ ln -snf /bin/true $TMPBINDIR/podman-compose
  $ pc

test additional argv::

  $ mkdir foo
  $ echo bar >> foo/bar
  $ grr bar
  foo/bar:bar

test alias list::

  $ jm-alias
  :q
  b
  d
  dc
  g
  gr
  gr_pics
  gr_video
  grr
  l
  ll
  p
  pc
  s
  t
