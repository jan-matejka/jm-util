setup linux::

  $ export HOME=$TMPDIR/home
  $ mkdir $HOME

setup podman::

  $ mkdir $TMPDIR/bin
  $ export PATH="$TMPDIR/bin:$PATH"
  $ cat >$TMPDIR/bin/podman <<EOF
  > #!/bin/zsh
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

not a worktree::

  $ jm claude
  jm-claude_: fatal: not a worktree (re)
  [1]

worktree no compose.yaml::

  $ git worktree add -q ../wip
  $ cd ../wip
  $ jm claude
  no configuration file provided: not found
  /tmp/dramtests-(.*)podman run -it --rm --name jm_claude_p_work_wip (.*) (re)


worktree with compose.yaml::

  $ echo 'name: foo' >compose.yaml
  $ jm claude
  /tmp/dramtests-(.*)/home/user/src/jm-claude/jm-claude.t.rst/tmp/bin/podman run -it --rm --name jm_claude_p_foo_wip --userns=keep-id:uid=1000,gid=1000 --cap-drop=ALL --security-opt=no-new-privileges --read-only -e DISABLE_DOCTOR_COMMAND=1 -v ./:/src/wip -v ../master:/src/master:ro -v jm-claude-local:/home/user/.local -v jm-claude-config:/home/user/.config -v /.*/.config/jm-util/claude/conf:/home/user/.config/claude -v /.*/.local/share/jm-util/claude/home/p/foo/wip:/home/user/.local/share/claude -v /.*/primary/default/settings.json:/home/user/.local/share/claude/settings.json -v /.*/primary/default/.credentials.json:/home/user/.local/share/claude/.credentials.json ghcr.io/jan-matejka/claude:latest (re)


worktree with a VM::

  $ export JM_CLAUDE_CONTAINER_HOST=foo.example.com
  $ export JM_CLAUDE_CONTAINER_SSHKEY=$TMPDIR/key
  $ export JM_CLAUDE_CONFIG_KNOWN_HOSTS=$TMPDIR/hosts
  $ jm claude
  /tmp/.* -e CONTAINER_HOST=foo.example.com -e CONTAINER_SSHKEY=/home/user/.ssh/id_ed25519 -v /.*/hosts:/home/user/.ssh/known_hosts:ro -v /.*/key:/home/user/.ssh/id_ed25519:ro .* (re)

chmod::

  $ stat -c '%a %A' $HOME/.config/jm-util/claude/conf
  750 drwxr-x---
  $ stat -c '%a %A' $HOME/.local/share/jm-util/claude/home/p/foo/wip
  750 drwxr-x---

command::

  $ jm claude zsh
  .*claude:latest zsh (re)

primary::

  $ jm claude -p
  .* -v /tmp/.*/home/.local/share/jm-util/claude/primary/default:/home/user/.local/share/claude .* (re)
