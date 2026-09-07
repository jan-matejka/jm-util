.. Note: to test the full flow without a real remote, this fakes ssh via
   GIT_SSH_COMMAND, running the "remote" git-upload-pack locally instead
   of over the network.

set up a fake ssh "remote" -- a bare repo one level under a fake home
directory, reachable via SCP-like host:org/repo.git syntax::

  $ mkdir -p remote-home/myorg
  $ git init -q --bare remote-home/myorg/myrepo.git
  $ git clone -q remote-home/myorg/myrepo.git work
  warning: You appear to have cloned an empty repository.
  $ cd work
  $ git config user.name J
  $ git config user.email j@e.c
  $ touch a
  $ git add a
  $ git commit -qam c1
  $ git push -q origin master
  $ cd ..
  $ cat > fake-ssh.sh <<'EOF'
  > #!/bin/sh
  > shift
  > cd "$PWD/remote-home" && exec sh -c "$*"
  > EOF
  $ chmod +x fake-ssh.sh

git-cl clones the SCP-like URL::

  $ export GIT_SSH_COMMAND="$PWD/fake-ssh.sh"
  $ mkdir dest
  $ git-cl fakehost:myorg/myrepo.git "$PWD/dest"
  Cloning into '*dest/myorg/myrepo/master'... (glob)
  $ test -d dest/myorg/myrepo/myrepo.git
  $ test -f dest/myorg/myrepo/master/a
  $ git -C dest/myorg/myrepo/master rev-parse --abbrev-ref HEAD
  master

git-cl defaults <dir> to $GIT_ORG_HOME when no <dir> is given::

  $ export GIT_ORG_HOME="$PWD/orghome"
  $ git-cl fakehost:myorg/myrepo.git
  Cloning into '*orghome/myorg/myrepo/master'... (glob)
  $ test -d "$GIT_ORG_HOME/myorg/myrepo/myrepo.git"
  $ test -f "$GIT_ORG_HOME/myorg/myrepo/master/a"

and falls back to ~/git when $GIT_ORG_HOME is unset::

  $ unset GIT_ORG_HOME
  $ mkdir fakehome
  $ export HOME="$PWD/fakehome"
  $ git-cl fakehost:myorg/myrepo.git
  Cloning into '*fakehome/git/myorg/myrepo/master'... (glob)
  $ test -d "$HOME/git/myorg/myrepo/myrepo.git"
  $ test -f "$HOME/git/myorg/myrepo/master/a"
