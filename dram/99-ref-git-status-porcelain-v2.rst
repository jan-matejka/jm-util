.. vim: tw=0 colorcolumn=0
.. ^
   - prevent automatic insertion of line breaks (tw)
   - unset colorcolumn to remove a line break column highlight

Example reference for the output of git status --porcelain=v2
#############################################################

Initialize a repository with a root commit:

  $ git init -q ./
  $ touch modified-tracked
  $ git add modified-tracked
  $ git commit -qam 'setup'

Setup reference:

  $ echo x > modified-tracked # modify tracked file
  $ touch newly-tracked; git add newly-tracked # start tracking a file
  $ touch untracked

Show reference:

  $ git status --porcelain=v2
  1 .M N... 100644 100644 100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 modified-tracked
  1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 newly-tracked
  ? untracked
