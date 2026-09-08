initialize a repository with a root commit::

  $ git init -q ./
  $ git config --local user.name "John"
  $ git config --local user.email "john@example.com"
  $ touch a
  $ git add a
  $ git commit -qam 'setup'

komitr -u alone, without -t fx, does not apply --fixup::

  $ echo target > ufile
  $ git add ufile
  $ git commit -qam 'target commit'
  $ TARGET=$(git rev-parse HEAD)
  $ echo >> ufile
  $ git add ufile
  $ EDITOR=: komitr -u $TARGET -q
  $ git log --pretty=%s -1
  ufile

komitr -t fx -u <commit> commits a fixup for the given commit, using
git's own "fixup! <subject>" message instead of komitr's own computed
subject::

  $ echo >> ufile
  $ git add ufile
  $ EDITOR=: komitr -t fx -u $TARGET -q
  $ git log --pretty=%s -1
  fixup! target commit

komitr -h alone, without -t fx, does not amend::

  $ echo x > hfile
  $ git add hfile
  $ git commit -qam 'setup hfile'
  $ git commit -q --allow-empty -m 'target commit'
  $ echo >> hfile
  $ git add hfile
  $ EDITOR=: komitr -h -q
  $ git log --pretty=%s -3
  hfile
  target commit
  setup hfile

komitr -h -t fx amends the current HEAD commit::

  $ git commit -q --allow-empty -m 'another target'
  $ echo >> hfile
  $ git add hfile
  $ EDITOR=: komitr -h -t fx -q
  $ git log --pretty=%s -3
  fx:hfile
  hfile
  target commit

komitr -h is not compatible with -d::

  $ echo >> hfile
  $ git add hfile
  $ EDITOR=: komitr -h -t fx -d -q
  komitr: fatal: -h is not compatible with -d
  [1]
