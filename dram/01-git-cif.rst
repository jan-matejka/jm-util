git-cif prints error if it can not find work dir root::

  $ git cif
  fatal: not a git repository (or any of the parent directories): .git
  git-cif: fatal: failed to find work dir
  [1]

initialize a repository with a root commit::

  $ git init -q ./
  $ touch a
  $ git add a
  $ git commit -qam 'setup'

git-cif commits changed files::

  $ echo x >> a
  $ git cif
  \[master [0-9a-f]{7}\] a (re)
   1 file changed, 1 insertion(+)

initialize subdirs in the git repository::

  $ mkdir -p foo/bar
  $ echo x >> foo/bar/b
  $ echo x >> c

  $ git add foo/bar/b c
  $ git commit -qam 'setup'

git-cif commits changed files in subdirs::

  $ echo x >> foo/bar/b
  $ echo x >> c

  $ cd foo && git cif
  \[master [0-9a-f]{7}\] c (re)
   1 file changed, 1 insertion(+)
  \[master [0-9a-f]{7}\] foo/bar/b (re)
   1 file changed, 1 insertion(+)

git-cif does not add untracked files by default::

  $ touch d
  $ git cif

Finally, check the messages of created commits::

  $ git log --format="%s" -5
  foo/bar/b
  c
  setup
  a
  setup

git-cif -w creates wip commits::

  $ echo bar > bar/b
  $ git cif -w
  \[master [0-9a-f]{7}\] wip: foo/bar/b (re)
   1 file changed, 1 insertion(+), 2 deletions(-)

git-cif prefixes the file with "add: " if a file becomes tracked::

  $ ! test -e c
  $ echo x > c
  $ git add c
  $ git cif
  \[master [0-9a-f]{7}\] add foo/c (re)
   1 file changed, 1 insertion(+)
   create mode 100644 foo/c

setup for git cif::

  $ mkdir -p bar
  $ mkdir -p qux
  $ touch bar/a qux/b
  $ git add bar qux

Note status.relativePaths affects porcelain as well::

  $ git -c status.relativePaths=0 status | grep 'new file' | sed 's/\t/     /'
       new file:   foo/bar/a
       new file:   foo/qux/b
  $ git -c status.relativePaths=1 status | grep 'new file' | sed 's/\t/     /'
       new file:   bar/a
       new file:   qux/b
  $ git -c status.relativePaths=0 status --porcelain=v2 | awk 'NF==9 { print $9 }'
  foo/bar/a
  foo/qux/b
  $ git -c status.relativePaths=1 status --porcelain=v2 | awk 'NF==9 { print $9 }'
  bar/a
  qux/b

But the -C flag handles it as well, regardless of relativePaths::

  $ git -c status.relativePaths=1 -C ../ status --porcelain=v2 | awk 'NF==9 { print $9 }'
  foo/bar/a
  foo/qux/b

git-cif -a::

  $ git cif -a
  \[master [0-9a-f]{7}\] foo: (re)
   2 files changed, 0 insertions(+), 0 deletions(-)
   create mode 100644 foo/bar/a
   create mode 100644 foo/qux/b
