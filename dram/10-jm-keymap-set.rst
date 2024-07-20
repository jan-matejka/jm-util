Setup::

  $ export JM_CONFIG_HOME=$TMPDIR/config
  $ export BINDIR=$TMPDIR/bin
  $ export PATH=$BINDIR:$PATH
  $ mkdir $BINDIR
  $ mkdir $JM_CONFIG_HOME

Config file does not exist::

  $ jm keymap set foo
  *jm-keymap-set:9: no such file or directory: */keymap/foo (glob)
  [1]

Setup::

  $ mkdir $JM_CONFIG_HOME/keymap
  $ cat >$JM_CONFIG_HOME/keymap/foo <<EOL
  > foo bar
  > bar qux
  > EOL

  $ cat >$BINDIR/setxkbmap << EOF
  > #!/usr/bin/zsh
  > printf "%s: %s\n" \$0 \${(pj: # :)@}
  > EOF
  $ chmod +x $BINDIR/setxkbmap
  $ ln -s /usr/bin/true $TMPDIR/bin/dzen2
  $ export NOTIFY=cat -

Config file exists::

  $ jm keymap set foo
  *setxkbmap: foo # bar (glob)
  *setxkbmap: bar # qux (glob)
  keymap: foo

Setup::

  $ rm $BINDIR/setxkbmap
  $ ln -s /usr/bin/false $BINDIR/setxkbmap

Failure of setxkbmap::

  $ jm keymap set foo
  *jm-keymap-set: failed to set keymap foo (no-eol) (glob)
  [1]
