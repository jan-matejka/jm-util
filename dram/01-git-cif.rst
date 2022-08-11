
  $ git cif
  fatal: not a git repository (or any of the parent directories): .git
  git-cif: fatal: failed to find work dir
  [1]

  $ git init -q ./
  $ touch a
  $ git add a
  $ git commit -qam 'setup'
  $ echo x >> a

  $ git cif
  \[master [0-9a-f]{7}\] wip: a (re)
   1 file changed, 1 insertion(+)


  $ mkdir -p foo/bar
  $ echo x >> foo/bar/b
  $ echo x >> c

  $ git add foo/bar/b c
  $ git commit -qam 'setup'

  $ echo x >> foo/bar/b
  $ echo x >> c
  $ touch d

  $ cd foo && git cif
  \[master [0-9a-f]{7}\] wip: c (re)
   1 file changed, 1 insertion(+)
  \[master [0-9a-f]{7}\] wip: foo/bar/b (re)
   1 file changed, 1 insertion(+)


  $ git log --format="%s" -3
  wip: foo/bar/b
  wip: c
  setup
