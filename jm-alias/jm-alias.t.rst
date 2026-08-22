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

  $ export TMPUSRBIN=$TMPDIR/usr-bin; mkdir $TMPUSRBIN
  $ ls /usr/bin | xargs -P $(nproc) -I% ln -snf /usr/bin/% $TMPUSRBIN/%
  $ rm $TMPUSRBIN/podman
  $ ln -snf `which jm-exec` $TMPBINDIR/jm-container-env-setup
  $ PATH="$TMPBINDIR:$PPATH:$TMPUSRBIN" pc
  /tmp/dramtests.*/jm-container-env-setup:3: command not found: podman (re)
  [127]

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
