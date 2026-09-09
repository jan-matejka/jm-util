setup linux::

  $ export HOME=$TMPDIR/home
  $ mkdir $HOME

setup podman::

  $ mkdir $TMPDIR/bin
  $ export PATH="$TMPDIR/bin:$PATH"
  $ cat >$TMPDIR/bin/podman <<EOF
  > #!/bin/zsh
  > printf "%s\n" \$0 \$@
  > EOF
  $ chmod +x $TMPDIR/bin/podman

-i works from outside a git repository (no git context is needed for an
instance-keyed container)::

  $ jm claude -i myinstance
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_i_myinstance
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  */data/i_myinstance:/src (glob)
  -v
  jm-claude-local-a-default:/home/user/.local
  -v
  jm-claude-config-a-default:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/default:/home/user/.config/claude (glob)
  -v
  */.local/share/jm-util/claude/home/i/myinstance:/home/user/.local/share/claude (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/.credentials.json:/home/user/.local/share/claude/.credentials.json (glob)
  ghcr.io/jan-matejka/claude:latest

setup git::

  $ git init -q master
  $ cd master
  $ git config --local user.name Foo
  $ git config --local user.email foo@example.com
  $ export GIT_COMMITTER_DATE='1970-01-01T00:00:00'
  $ export GIT_AUTHOR_DATE='1970-01-01T00:00:00'
  $ touch a; git add a; git commit -qam 'init'

default topology (no worktree)::

  $ jm claude
  no configuration file provided: not found
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_p_work_master
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  ./:/src
  -v
  */master/.git:/run/jm-claude/git-common-ro:ro (glob)
  -v
  */gitdir/*/master:/src/.git (glob)
  -v
  */gitdir/*/master.alternates:/src/.git/objects/info/alternates:ro (glob)
  -v
  jm-claude-local-a-default:/home/user/.local
  -v
  jm-claude-config-a-default:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/default:/home/user/.config/claude (glob)
  -v
  */.local/share/jm-util/claude/home/p/work/master:/home/user/.local/share/claude (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/.credentials.json:/home/user/.local/share/claude/.credentials.json (glob)
  ghcr.io/jan-matejka/claude:latest

worktree no compose.yaml::

  $ git worktree add -q ../wip
  $ cd ../wip
  $ jm claude
  no configuration file provided: not found
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_p_work_wip
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  ./:/src
  -v
  */master/.git:/run/jm-claude/git-common-ro:ro (glob)
  -v
  */master/.git/worktrees/wip:/run/jm-claude/git-work-ro:ro (glob)
  -v
  */gitdir/*/wip:/run/jm-claude/git-local (glob)
  -v
  */gitdir/*/wip.gitlink:/src/.git:ro (glob)
  -v
  */gitdir/*/wip.alternates:/run/jm-claude/git-local/objects/info/alternates:ro (glob)
  -v
  jm-claude-local-a-default:/home/user/.local
  -v
  jm-claude-config-a-default:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/default:/home/user/.config/claude (glob)
  -v
  */.local/share/jm-util/claude/home/p/work/wip:/home/user/.local/share/claude (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/.credentials.json:/home/user/.local/share/claude/.credentials.json (glob)
  ghcr.io/jan-matejka/claude:latest

git-local's refs are seeded flat, not nested under refs/refs (regression for
a cp -r bug that silently dropped every branch ref: git init already creates
an empty refs/{heads,tags} skeleton, and `cp -r src dst` nests src *inside*
an already-existing dst instead of merging into it)::

  $ find $HOME/.local/share/jm-util/claude/gitdir -type f -path '*/wip/refs/heads/wip'
  */wip/refs/heads/wip (glob)
  $ find $HOME/.local/share/jm-util/claude/gitdir -type d -path '*/wip/refs/refs'


worktree with compose.yaml::

  $ echo 'name: foo' >compose.yaml
  $ jm claude
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_p_foo_wip
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  ./:/src
  -v
  */master/.git:/run/jm-claude/git-common-ro:ro (glob)
  -v
  */master/.git/worktrees/wip:/run/jm-claude/git-work-ro:ro (glob)
  -v
  */gitdir/*/wip:/run/jm-claude/git-local (glob)
  -v
  */gitdir/*/wip.gitlink:/src/.git:ro (glob)
  -v
  */gitdir/*/wip.alternates:/run/jm-claude/git-local/objects/info/alternates:ro (glob)
  -v
  jm-claude-local-a-default:/home/user/.local
  -v
  jm-claude-config-a-default:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/default:/home/user/.config/claude (glob)
  -v
  */.local/share/jm-util/claude/home/p/foo/wip:/home/user/.local/share/claude (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/.credentials.json:/home/user/.local/share/claude/.credentials.json (glob)
  ghcr.io/jan-matejka/claude:latest


account is read from project.toml's tool.jmutil.claude.account by default::

  $ printf '[tool.jmutil.claude]\naccount = "cfgacct"\n' > project.toml
  $ jm claude
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_p_foo_wip
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  ./:/src
  -v
  */master/.git:/run/jm-claude/git-common-ro:ro (glob)
  -v
  */master/.git/worktrees/wip:/run/jm-claude/git-work-ro:ro (glob)
  -v
  */gitdir/*/wip:/run/jm-claude/git-local (glob)
  -v
  */gitdir/*/wip.gitlink:/src/.git:ro (glob)
  -v
  */gitdir/*/wip.alternates:/run/jm-claude/git-local/objects/info/alternates:ro (glob)
  -v
  jm-claude-local-a-cfgacct:/home/user/.local
  -v
  jm-claude-config-a-cfgacct:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/cfgacct:/home/user/.config/claude (glob)
  -v
  */.local/share/jm-util/claude/home/p/foo/wip:/home/user/.local/share/claude (glob)
  -v
  */primary/cfgacct/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/cfgacct/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/cfgacct/.credentials.json:/home/user/.local/share/claude/.credentials.json (glob)
  ghcr.io/jan-matejka/claude:latest

an explicit -a/--account wins over project.toml's configured account::

  $ jm claude -a explicit
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_p_foo_wip
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  ./:/src
  -v
  */master/.git:/run/jm-claude/git-common-ro:ro (glob)
  -v
  */master/.git/worktrees/wip:/run/jm-claude/git-work-ro:ro (glob)
  -v
  */gitdir/*/wip:/run/jm-claude/git-local (glob)
  -v
  */gitdir/*/wip.gitlink:/src/.git:ro (glob)
  -v
  */gitdir/*/wip.alternates:/run/jm-claude/git-local/objects/info/alternates:ro (glob)
  -v
  jm-claude-local-a-explicit:/home/user/.local
  -v
  jm-claude-config-a-explicit:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/explicit:/home/user/.config/claude (glob)
  -v
  */.local/share/jm-util/claude/home/p/foo/wip:/home/user/.local/share/claude (glob)
  -v
  */primary/explicit/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/explicit/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/explicit/.credentials.json:/home/user/.local/share/claude/.credentials.json (glob)
  ghcr.io/jan-matejka/claude:latest
  $ rm -f project.toml

worktree with a VM::

  $ export JM_CLAUDE_CONTAINER_HOST=foo.example.com
  $ export JM_CLAUDE_CONTAINER_SSHKEY=$TMPDIR/key
  $ export JM_CLAUDE_CONFIG_KNOWN_HOSTS=$TMPDIR/hosts
  $ jm claude
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_p_foo_wip
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  ./:/src
  -v
  */master/.git:/run/jm-claude/git-common-ro:ro (glob)
  -v
  */master/.git/worktrees/wip:/run/jm-claude/git-work-ro:ro (glob)
  -v
  */gitdir/*/wip:/run/jm-claude/git-local (glob)
  -v
  */gitdir/*/wip.gitlink:/src/.git:ro (glob)
  -v
  */gitdir/*/wip.alternates:/run/jm-claude/git-local/objects/info/alternates:ro (glob)
  -v
  jm-claude-local-a-default:/home/user/.local
  -v
  jm-claude-config-a-default:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/default:/home/user/.config/claude (glob)
  -v
  */.local/share/jm-util/claude/home/p/foo/wip:/home/user/.local/share/claude (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/.credentials.json:/home/user/.local/share/claude/.credentials.json (glob)
  -e
  CONTAINER_HOST=foo.example.com
  -e
  CONTAINER_SSHKEY=/home/user/.ssh/id_ed25519
  -v
  */hosts:/home/user/.ssh/known_hosts:ro (glob)
  -v
  */key:/home/user/.ssh/id_ed25519:ro (glob)
  ghcr.io/jan-matejka/claude:latest

chmod::

  $ stat -c '%a %A' $HOME/.config/jm-util/claude/conf/account/default
  750 drwxr-x---
  $ stat -c '%a %A' $HOME/.local/share/jm-util/claude/home/p/foo/wip
  750 drwxr-x---

command::

  $ jm claude zsh
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_p_foo_wip
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  ./:/src
  -v
  */master/.git:/run/jm-claude/git-common-ro:ro (glob)
  -v
  */master/.git/worktrees/wip:/run/jm-claude/git-work-ro:ro (glob)
  -v
  */gitdir/*/wip:/run/jm-claude/git-local (glob)
  -v
  */gitdir/*/wip.gitlink:/src/.git:ro (glob)
  -v
  */gitdir/*/wip.alternates:/run/jm-claude/git-local/objects/info/alternates:ro (glob)
  -v
  jm-claude-local-a-default:/home/user/.local
  -v
  jm-claude-config-a-default:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/default:/home/user/.config/claude (glob)
  -v
  */.local/share/jm-util/claude/home/p/foo/wip:/home/user/.local/share/claude (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/settings.json:/home/user/.local/share/claude/settings.json (glob)
  -v
  */primary/default/.credentials.json:/home/user/.local/share/claude/.credentials.json (glob)
  -e
  CONTAINER_HOST=foo.example.com
  -e
  CONTAINER_SSHKEY=/home/user/.ssh/id_ed25519
  -v
  */hosts:/home/user/.ssh/known_hosts:ro (glob)
  -v
  */key:/home/user/.ssh/id_ed25519:ro (glob)
  ghcr.io/jan-matejka/claude:latest
  zsh

primary::

  $ jm claude -p
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_primary
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  */data/primary:/src (glob)
  -v
  jm-claude-local-a-default:/home/user/.local
  -v
  jm-claude-config-a-default:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/default:/home/user/.config/claude (glob)
  -v
  */primary/default:/home/user/.local/share/claude (glob)
  -e
  CONTAINER_HOST=foo.example.com
  -e
  CONTAINER_SSHKEY=/home/user/.ssh/id_ed25519
  -v
  */hosts:/home/user/.ssh/known_hosts:ro (glob)
  -v
  */key:/home/user/.ssh/id_ed25519:ro (glob)
  ghcr.io/jan-matejka/claude:latest

distinct accounts use distinct config dirs::

  $ jm claude -p -a acct1
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_primary
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  */data/primary:/src (glob)
  -v
  jm-claude-local-a-acct1:/home/user/.local
  -v
  jm-claude-config-a-acct1:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/acct1:/home/user/.config/claude (glob)
  -v
  */primary/acct1:/home/user/.local/share/claude (glob)
  -e
  CONTAINER_HOST=foo.example.com
  -e
  CONTAINER_SSHKEY=/home/user/.ssh/id_ed25519
  -v
  */hosts:/home/user/.ssh/known_hosts:ro (glob)
  -v
  */key:/home/user/.ssh/id_ed25519:ro (glob)
  ghcr.io/jan-matejka/claude:latest

  $ jm claude -p -a acct2
  */bin/podman (glob)
  run
  -it
  --rm
  --name
  jm_claude_primary
  --userns=keep-id:uid=1000,gid=1000
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  -e
  DISABLE_DOCTOR_COMMAND=1
  -v
  */data/primary:/src (glob)
  -v
  jm-claude-local-a-acct2:/home/user/.local
  -v
  jm-claude-config-a-acct2:/home/user/.config
  -v
  */.config/jm-util/claude/conf/account/acct2:/home/user/.config/claude (glob)
  -v
  */primary/acct2:/home/user/.local/share/claude (glob)
  -e
  CONTAINER_HOST=foo.example.com
  -e
  CONTAINER_SSHKEY=/home/user/.ssh/id_ed25519
  -v
  */hosts:/home/user/.ssh/known_hosts:ro (glob)
  -v
  */key:/home/user/.ssh/id_ed25519:ro (glob)
  ghcr.io/jan-matejka/claude:latest
