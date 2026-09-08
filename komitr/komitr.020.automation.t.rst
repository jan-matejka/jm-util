initialize a repository with a root commit::

  $ git init -q ./
  $ git config --local user.name "John"
  $ git config --local user.email "john@example.com"
  $ touch a
  $ git add a
  $ git commit -qam 'setup'

komitr -d honors the -m value::

  $ echo x >> a
  $ git add a
  $ komitr -dqm "msg"
  $ git log -1 --pretty=%s
  a: msg

komitr -w::

  $ echo >>a
  $ EDITOR=: komitr -awq
  $ git log -1 --pretty=%s
  wip:a

komitr prefixes the message with "add " when the single committed file is
newly tracked::

  $ echo x > newfile
  $ git add newfile
  $ EDITOR=: komitr -q
  $ git log -1 --pretty=%s
  ft:newfile: add

and not when more than one file is committed::

  $ mkdir pkg
  $ touch pkg/x pkg/y
  $ git add pkg
  $ EDITOR=: komitr -q
  $ git log -1 --pretty=%s
  pkg

komitr -d also gets "add " (and -w) for free through recursion into the
same non-discrete message-building path::

  $ echo x > discrete-new
  $ git add discrete-new
  $ komitr -dqw
  $ git log -1 --pretty=%s
  wip:ft:discrete-new: add

rm marker::

  $ echo delete > deleted
  $ git add deleted
  $ git commit -qam 'delete me'
  $ git rm -q deleted
  $ EDITOR=: komitr -q
  $ git log -1 --pretty=%s
  rm:deleted

komitr commits a rename without an add or rm marker::

  $ mkdir ren
  $ echo x > ren/old
  $ git add ren
  $ git commit -qam 'setup rename fixture'
  $ git mv ren/old ren/new
  $ EDITOR=: komitr -q
  $ git log -1 --pretty=%s
  mv:ren

komitr -d commits a rename atomically, as a single commit::

  $ mkdir ren2
  $ echo x > ren2/old
  $ git add ren2
  $ git commit -qam 'setup rename fixture 2'
  $ git mv ren2/old ren2/new
  $ EDITOR=: komitr -dq
  $ git log -1 --pretty=%s
  mv:ren2
  $ git status --porcelain=v2

komitr -t sets an explicit commit type prefix::

  $ echo x > widget.txt
  $ git add widget.txt
  $ git commit -qam 'setup widget'
  $ echo y >> widget.txt
  $ git add widget.txt
  $ EDITOR=: komitr -q -t feat -m 'support flux capacitor'
  $ git log -1 --pretty=%s
  feat:widget: support flux capacitor

komitr -t overrides the automatic "rm" type on a deletion::

  $ echo z > todelete
  $ git add todelete
  $ git commit -qam 'setup todelete'
  $ git rm -q todelete
  $ EDITOR=: komitr -q -t chore -m cleanup
  $ git log -1 --pretty=%s
  chore:todelete: cleanup

komitr -t overrides the automatic "ft" type on a newly tracked file::

  $ echo x > newthing.txt
  $ git add newthing.txt
  $ EDITOR=: komitr -q -t feat
  $ git log -1 --pretty=%s
  feat:newthing: add

komitr builds an "old -> new" message for a rename given as explicit
pathspec arguments, instead of recursing::

  $ mkdir arr
  $ echo z > arr/before
  $ git add arr
  $ git commit -qam 'setup arr'
  $ git mv arr/before arr/after
  $ EDITOR=: komitr -q arr/before arr/after
  $ git log -1 --pretty=%s
  mv:arr: arr/before -> arr/after

komitr -a still commits all tracked changes even when an explicit
pathspec is also given: the scope is computed from everything that
actually gets committed, not just the named pathspec, so unrelated
files with no common path end up with no scope at all::

  $ echo w > multi1
  $ echo v > multi2
  $ git add multi1 multi2
  $ git commit -qam 'setup multi'
  $ echo edit1 >> multi1
  $ echo edit2 >> multi2
  $ EDITOR=: komitr -aq -m 'edit multiple' multi1
  $ git log -1 --pretty=%s
  : edit multiple
