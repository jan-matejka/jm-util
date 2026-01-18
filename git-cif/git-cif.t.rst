.. Note: git status --porcelain=v2 output is shown in
   dram/99-ref-git-status-porcelain-v2.rst

initialize a repository with a root commit::

  $ git init -q ./
  $ git config --local user.name "John"
  $ git config --local user.email "john@example.com"
  $ git config --local alias.lg "log '--pretty=format:%B' --name-status"
  $ touch a
  $ git add a
  $ git commit -qam 'setup'

git-cif does nothing if there is no index::

  $ echo x >> a
  $ git cif
  On branch master
  Changes not staged for commit:
    (use "git add <file>..." to update what will be committed)
    (use "git restore <file>..." to discard changes in working directory)
  \tmodified:   a (re)
  
  no changes added to commit (use "git add" and/or "git commit -a")
  [255]

git cif commits changes in index::

  $ git add a
  $ git cif -qm ""
  $ git lg -1
  a
  
  M	a

git cif -a commits all changes::

  $ echo x >> a
  $ git cif -aqm ""
  $ git lg -1
  a
  
  M	a

initialize subdirs in the git repository::

  $ mkdir -p foo/bar
  $ echo x >> foo/bar/b
  $ echo x >> c

  $ git add foo/bar/b c
  $ git commit -qam 'setup'

git-cif commits changed files in subdirs::

  $ echo x >> foo/bar/b
  $ echo x >> c

  $ cd foo && git cif -dqam ""
  $ git lg -2
  foo/bar/b:
  
  M	foo/bar/b
  
  c:
  
  M	c

git-cif -a does not add untracked files by default::

  $ touch d
  $ git cif -dam ""
  $ git cif -am ""
  On branch master
  Untracked files:
    (use "git add <file>..." to include in what will be committed)
  	foo/d
  
  nothing added to commit but untracked files present (use "git add" to track)
  [255]


Finally, check the messages of created commits::

  $ git log --format="%s" -6
  foo/bar/b:
  c:
  setup
  a
  a
  setup

git-cif -aw creates wip commits::

  $ echo bar > bar/b
  $ git add bar/b
  $ git cif -dqam "" -w
  $ git lg -1
  wip: foo/bar/b:
  
  M	foo/bar/b

git-cif prefixes the file with "add: " if a file becomes tracked::

  $ ! test -e c
  $ echo x > c
  $ git add c
  $ git cif -qm ""
  $ git lg -1
  foo/c
  
  A	foo/c

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

git-cif::

  $ git cif -qm ""
  $ git lg -1
  foo
  
  A	foo/bar/a
  A	foo/qux/b

git-cif on staged changes::

  $ echo a >> bar/a
  $ echo a >> bar/c
  $ echo b >> bar/b
  $ git add bar/a bar/c
  $ git cif -qm ""
  $ git lg -1
  foo/bar
  
  M	foo/bar/a
  A	foo/bar/c

  $ git status -s
   M bar/b
  ?? d
  $ git clean -fdxq
  $ git reset --hard -q

git-cif -m::

  $ echo a >> bar/a
  $ git add bar
  $ git cif -qm "foom"
  $ git lg -1
  foo/bar/a: foom
  
  M	foo/bar/a

get back to GIT_WORK_TREE root::

  $ cd ..

git-cif aborts when there is no lcpp and no editor::

  $ echo a >> a
  $ echo a >> c
  $ git add a c
  $ git cif
  error: Terminal is dumb, but EDITOR unset
  Please supply the message using either -m or -F option.
  [255]

git-cif aborts when there is no lcpp and editor does not edit the message::

  $ echo a >> a
  $ echo a >> c
  $ git add a c
  $ EDITOR=cat git cif -q
  
  # Please enter the commit message for your changes. Lines starting
  # with '#' will be ignored, and an empty message aborts the commit.
  #
  # On branch master
  # Changes to be committed:
  #\tmodified:   a (re)
  #\tmodified:   c (re)
  #
  Aborting commit due to empty commit message.
  [255]

git commit -m but no value given::

  $ git commit -m
  error: switch `m' requires a value
  [129]

git cif -m but no value given::

  $ git cif -m
  */build/bin/git-cif:zparseopts:19: missing argument for option: -m (glob)
  [1]

  
git-cif aborts when there is no lcpp and -m is given but empty::

  $ echo a >> a
  $ echo a >> c
  $ git add a c
  $ git cif -q -m ''
  Aborting commit due to empty commit message.
  [255]

git-cif commits as usual when there is no lcpp but -m is given::

  $ echo a >> a
  $ echo a >> c
  $ git add a c
  $ EDITOR=cat git cif -q -m 'foo'
  $ git log -1 --pretty=format:%s%n
  : foo

git-cif commits as usual when there is no lcpp and no -m but editor supplies
the message::

  $ echo a >> a
  $ echo a >> c
  $ git add a c
  $ EDITOR='bash -c "echo bar >>$1" "echo"'  git cif -q
  $ git log -1 --pretty=format:%s%n
  bar

git-cif -d does --no-edit by default::

  $ echo a >> a
  $ EDITOR=false git cif -adq
