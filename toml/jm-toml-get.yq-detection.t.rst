setup a repository::

  $ git init -q ./
  $ git config --local user.name John
  $ git config --local user.email john@example.com
  $ touch a; git add a; git commit -qam setup

setup a yq-free PATH -- an explicit whitelist of just the external
tools jm/jm-toml-get actually need (zsh for the #!/usr/bin/env zsh
shebangs, git, and xdgenv-exec/xdgenv-prelude for the jm dispatcher),
so the "no yq" tests below are deterministic regardless of whether
yq-go/yq happen to be installed on the real system running this
suite -- not merely absent by sandbox coincidence::

  $ mkdir $TMPDIR/noyq
  $ for t in zsh git xdgenv-exec xdgenv-prelude; do
  >   ln -s "$(command -v $t)" "$TMPDIR/noyq/$t"
  > done

setup fake yq-go and yq -- each just claims every key is present and
prints a marker identifying itself, so tests below can assert *which*
one jm-toml-get picked without needing a real TOML parser::

  $ mkdir $TMPDIR/fakeyq
  $ cat >$TMPDIR/fakeyq/yq-go <<'EOF'
  > #!/bin/sh
  > case "$*" in
  >   *'has('*) echo true ;;
  >   *) echo "via-yq-go" ;;
  > esac
  > EOF
  $ cat >$TMPDIR/fakeyq/yq <<'EOF'
  > #!/bin/sh
  > case "$*" in
  >   *'has('*) echo true ;;
  >   *) echo "via-yq" ;;
  > esac
  > EOF
  $ chmod +x $TMPDIR/fakeyq/yq-go $TMPDIR/fakeyq/yq
  $ printf 'x = 1\n' > project.toml

yq-go is preferred over yq when both are on PATH::

  $ PATH=$TMPDIR/fakeyq:$PATH jm toml-get x
  via-yq-go

yq is used when only it is on PATH (yq-go absent)::

  $ mkdir $TMPDIR/fakeyq-only-yq
  $ cp $TMPDIR/fakeyq/yq $TMPDIR/fakeyq-only-yq/yq
  $ PATH=$TMPDIR/fakeyq-only-yq:$PPATH:$TMPDIR/noyq jm toml-get x
  jm-toml-get: warning: command not found: yq-go
  via-yq

JM_UTIL_YQ, if already set, is used as-is (no auto-detection), even
when a preferred candidate is also on PATH::

  $ PATH=$TMPDIR/fakeyq:$PATH JM_UTIL_YQ=yq jm toml-get x
  via-yq
  $ rm -f project.toml

no yq-go/yq available -- warns, behaves as absent::

  $ PATH=$PPATH:$TMPDIR/noyq jm toml-get tool.jmutil.claude.account
  jm-toml-get: warning: command not found: yq-go
  jm-toml-get: warning: command not found: yq
  jm-toml-get: fatal: no yq
  [1]
  $ PATH=$PPATH:$TMPDIR/noyq jm toml-get tool.jmutil.claude.account default
  jm-toml-get: warning: command not found: yq-go
  jm-toml-get: warning: command not found: yq
  default

no yq-go/yq available -- warns, behaves as absent, even when
project.toml exists (regression: an empty $JM_UTIL_YQ must not reach
the yq invocation below)::

  $ printf 'x = 1\n' > project.toml
  $ PATH=$PPATH:$TMPDIR/noyq jm toml-get x
  jm-toml-get: warning: command not found: yq-go
  jm-toml-get: warning: command not found: yq
  jm-toml-get: fatal: no yq
  [1]
  $ rm -f project.toml
