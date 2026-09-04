.. vim: tw=0 colorcolumn=0
.. ^
   - prevent automatic insertion of line breaks (tw)
   - unset colorcolumn to remove a line break column highlight

Example reference for the output of git status --porcelain=v2
#############################################################

Initialize a repository with a root commit::

  $ git init -q ./
  $ git config --local user.name "John"
  $ git config --local user.email "john@example.com"
  $ touch modified-tracked
  $ echo deleted > deleted
  $ echo moved > moved-a
  $ git add modified-tracked moved-a deleted
  $ git commit -qam 'setup'

Setup reference::

  $ echo x > modified-tracked # modify tracked file
  $ touch newly-tracked; git add newly-tracked # start tracking a file
  $ touch untracked
  $ git mv moved-a moved-b
  $ git rm -q deleted

Status::

  $ git status
  On branch master
  Changes to be committed:
    (use "git restore --staged <file>..." to unstage)
  	deleted:    deleted
  	renamed:    moved-a -> moved-b
  	new file:   newly-tracked
  
  Changes not staged for commit:
    (use "git add <file>..." to update what will be committed)
    (use "git restore <file>..." to discard changes in working directory)
  	modified:   modified-tracked
  
  Untracked files:
    (use "git add <file>..." to include in what will be committed)
  	untracked
  

Porcelain::

  $ git status --porcelain=v2
  1 D. N... 100644 000000 000000 [a-f0-9]{40} [a-f0-9]{40} deleted (re)
  1 .M N... 100644 100644 100644 [a-f0-9]{40} [a-f0-9]{40} modified-tracked (re)
  2 R. N... 100644 100644 100644 [a-f0-9]{40} [a-f0-9]{40} R100 moved-b	moved-a (re)
  1 A. N... 000000 100644 100644 [a-f0-9]{40} [a-f0-9]{40} newly-tracked (re)
  ? untracked

Porcelain with pathspec::

  $ git status --porcelain=v2 -- deleted
  1 D. N... 100644 000000 000000 [a-f0-9]{40} [a-f0-9]{40} deleted (re)

Porcelain with sep but no pathspec is identical to no sep::

  $ git status --porcelain=v2 --
  1 D. N... 100644 000000 000000 [a-f0-9]{40} [a-f0-9]{40} deleted (re)
  1 .M N... 100644 100644 100644 [a-f0-9]{40} [a-f0-9]{40} modified-tracked (re)
  2 R. N... 100644 100644 100644 [a-f0-9]{40} [a-f0-9]{40} R100 moved-b	moved-a (re)
  1 A. N... 000000 100644 100644 [a-f0-9]{40} [a-f0-9]{40} newly-tracked (re)
  ? untracked

Pathspec renames::

  $ git status --porcelain=v2 -- moved-b
  1 A. N... 000000 100644 100644 [a-f0-9]{40} [a-f0-9]{40} moved-b (re)
  $ git status --porcelain=v2 -- moved-a
  1 D. N... 100644 000000 000000 [a-f0-9]{40} [a-f0-9]{40} moved-a (re)
  $ git status --porcelain=v2 -- moved-a moved-b
  2 R. N... 100644 100644 100644 [a-f0-9]{40} [a-f0-9]{40} R100 moved-b	moved-a (re)

Multiple renames in a dir::

  $ git commit -qam 'clean'
  $ mkdir foo
  $ echo a > foo/a
  $ echo b > foo/b
  $ git add foo
  $ git commit -qam 'foo'
  $ git mv foo bar
  $ git status --porcelain=v2
  2 R. N... 100644 100644 100644 [a-f0-9]{40} [a-f0-9]{40} R100 bar/a	foo/a (re)
  2 R. N... 100644 100644 100644 [a-f0-9]{40} [a-f0-9]{40} R100 bar/b	foo/b (re)
  ? untracked

Unstaged rename::

  $ git commit -qam 'clean'
  $ git mv bar foo
  $ git reset -q
  $ git status --porcelain=v2
  1 .D N... 100644 100644 000000 [a-f0-9]{40} [a-f0-9]{40} bar/a (re)
  1 .D N... 100644 100644 000000 [a-f0-9]{40} [a-f0-9]{40} bar/b (re)
  ? foo/
  ? untracked

Partially staged::

  $ git commit -qam 'clean'
  $ echo x >> foo/a
  $ git add foo/a
  $ echo y >> foo/a
  $ git status --porcelain=v2
  1 AM N... 000000 100644 100644 [a-f0-9]{40} [a-f0-9]{40} foo/a (re)
  \? .* (re)
  \? .* (re)

Double add::

  $ echo x >> foo/a
  $ git add foo/a
  $ git add foo/a
