  $ export XDG_STATE_HOME=$TMPDIR/state
  $ export GIT_CONFIG_SYSTEM=/dev/null
  $ export GIT_CONFIG_GLOBAL=/dev/null

  $ jm versionator -d
  fatal: not a git repository .* (re)
  [128]

  $ git init -q ./
  $ git config --local user.name Foo
  $ git config --local user.email foo@example.com
  $ export GIT_COMMITTER_DATE='1970-01-01T00:00:00'
  $ export GIT_AUTHOR_DATE='1970-01-01T00:00:00'

  $ jm versionator -d
  fatal: No names found, cannot describe anything.
  [128]

  $ touch foo; git add foo; git commit -aqm 'foo'
  $ jm versionator -d
  fatal: No names found, cannot describe anything.
  [128]

  $ git tag v/0.1.0
  $ jm versionator -d
  jm-versionator: version=0.1.0

  $ jm versionator -dq
  0.1.0

  $ touch bar
  $ jm versionator -d
  jm-versionator: version=0.1.0+2.dirty
  $ jm versionator -dv
  jm-versionator: build_id++ because detected 0.1.0-dirty is dirty
  jm-versionator: build_id inserted because detected version 0.1.0-dirty is dirty
  jm-versionator: version=0.1.0+3.dirty

  $ git add bar; git commit -aqm bar
  $ jm-versionator -d
  jm-versionator: version=0.1.0+4.1.g9330b9f
  $ jm-versionator -dv
  jm-versionator: build_id++ because detected 0.1.0-1-g9330b9f is commit
  jm-versionator: build_id inserted because detected version 0.1.0-1-g9330b9f is commit
  jm-versionator: version=0.1.0+5.1.g9330b9f

  $ touch qux
  $ jm-versionator -d
  jm-versionator: version=0.1.0+6.1.g9330b9f.dirty
  $ jm-versionator -dv
  jm-versionator: build_id++ because detected 0.1.0-1-g9330b9f-dirty is dirty
  jm-versionator: build_id inserted because detected version 0.1.0-1-g9330b9f-dirty is dirty commit
  jm-versionator: version=0.1.0+7.1.g9330b9f.dirty

  $ git add qux; git commit -aqm foo; git tag v/0.1.1
  $ jm-versionator -d
  jm-versionator: version=0.1.1
  $ jm-versionator -dv
  jm-versionator: version=0.1.1

  $ echo . >> qux
  $ jm-versionator -dq
  0.1.1+8.dirty
  $ jm-versionator -dqv
  jm-versionator: build_id++ because detected 0.1.1-dirty is dirty
  jm-versionator: build_id inserted because detected version 0.1.1-dirty is dirty
  0.1.1+9.dirty

  $ mkdir debian; export EMAIL=foo@example.com;
  $ export NAME=Alice # name to use for dch --create instead of the linux username
  $ EDITOR=true dch --create --date "$(date -R -d @20)" --package foo -v 0.1.0-1 init
  $ git add debian; git commit -aqm changelog
  $ jm-versionator -dqv
  jm-versionator: build_id=1 because detected base of 0.1.1-1-gc194cab > last 0.1.0
  jm-versionator: build_id inserted because detected version 0.1.1-1-gc194cab is commit
  0.1.1+1.1.gc194cab

  # The base version can increase only by a new version tag. However, the tag
  # need not be HEAD, just reachable.
  $ git tag v/0.1.2
  $ echo . > foo; git commit -aqm foo
  $ jm-versionator -dq
  0.1.2\+1.1.g[0-9a-z]{7} (re)

  $ export JMU_VERSIONATOR_DCH_DATE="$(date -R -d @20)"
  $ jm-versionator -dq --dch
  0.1.2\+1.1.g[0-9a-z]{7} (re)
  $ git diff
  diff --git a/debian/changelog b/debian/changelog
  index 515509f..1658315 100644
  --- a/debian/changelog
  +++ b/debian/changelog
  @@ -1,4 +1,4 @@
  -foo (0.1.0-1) UNRELEASED; urgency=medium
  +foo (0.1.2+1.1.g4a2c131-1) UNRELEASED; urgency=medium
  \s+ (re)
     * init
  \s+ (re)

  $ jm-versionator -dq --output-shell foo.sh
  0.1.2+2.1.g4a2c131.dirty
  $ sh foo.sh -q
  0.1.2+2.1.g4a2c131.dirty

  $ echo . >> foo; git commit -qam 'foo'
  $ jm-versionator --dch --output-shell foo.sh "0.1.3"
  foo.sh: version=0.1.3
  gbp:info: Changelog last touched at 'fb6a356913befe099f8db4f27ef7b3e719f0ec33'
  gbp:info: Continuing from commit 'fb6a356913befe099f8db4f27ef7b3e719f0ec33'
  gbp:info: No changes detected from fb6a356913befe099f8db4f27ef7b3e719f0ec33 to HEAD.

  $ git show HEAD~1
  commit fb6a356913befe099f8db4f27ef7b3e719f0ec33
  Author: Foo <foo@example.com>
  Date:   Thu Jan 1 00:00:00 1970 +0000
  \s* (re)
      foo
  \s* (re)
  diff --git a/debian/changelog b/debian/changelog
  index 515509f..1658315 100644
  --- a/debian/changelog
  +++ b/debian/changelog
  @@ -1,4 +1,4 @@
  -foo (0.1.0-1) UNRELEASED; urgency=medium
  +foo (0.1.2+1.1.g4a2c131-1) UNRELEASED; urgency=medium
  \s* (re)
     * init
  \s* (re)
  diff --git a/foo b/foo
  index 9c558e3..ac860a3 100644
  --- a/foo
  +++ b/foo
  @@ -1 +1,2 @@
   .
  +.

  $ git log --oneline --decorate --graph -3
  * 195db9c (HEAD -> master, tag: v/0.1.3) version 0.1.3
  * fb6a356 foo
  * 4a2c131 foo

  $ touch quux
  $ jm versionator 0.1.3
  ?? foo.sh
  ?? quux
  jm-versionator: release is dirty; abort
  [1]

  $ jm versionator ""
  .*: 1: Missing <version> argument (re)
  [1]
