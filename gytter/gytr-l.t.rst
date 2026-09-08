.. Note: gytr-l colorizes its output when stdout is a terminal. dram's
   captured output isn't a tty, so these tests actually run uncolored,
   but lines that would contain color escape codes when run
   interactively are still matched with (re) patterns loose enough to
   not care about exact codes/positions -- only that the meaningful text
   is present -- so they stay correct either way.

gytr-l shows each commit's position relative to the current branch, using
git's own rev-spec notation::

  $ git init -q ./
  $ git config --local user.name "John"
  $ git config --local user.email "john@example.com"
  $ touch a && git add a && git commit -qam "commit 1"
  $ touch b && git add b && git commit -qam "commit 2"
  $ touch c && git add c && git commit -qam "commit 3"
  $ gytr-l --all
  .*master.*commit 3.* (re)
  .*master~1.*commit 2.* (re)
  .*master~2.*commit 1.* (re)

Gytr-l -h still prints a plain, uncolored hash list::

  $ gytr-l -h --all | awk 1
  [0-9a-f]{40} (re)
  [0-9a-f]{40} (re)
  [0-9a-f]{40} (re)

A commit reached only via a merge's non-first parent gets a correct
branch^2-style label instead of a blank or fabricated one::

  $ git checkout -qb feature HEAD~1
  $ touch feature-file && git add feature-file && git commit -qam "feature commit"
  $ git checkout -q master
  $ git merge -q --no-ff feature -m "merge feature"
  $ gytr-l --all
  .*master.*merge feature.* (re)
  .* (re)
  .*master\^2.*feature commit.* (re)
  .*master~1.*commit 3.* (re)
  .* (re)
  .*master~2.*commit 2.* (re)
  .*master~3.*commit 1.* (re)

With no args, gytr-l shows the full log when the current branch is the
repo's default branch::

  $ git config --local init.defaultBranch master
  $ gytr-l
  .*master.*merge feature.* (re)
  .* (re)
  .*master\^2.*feature commit.* (re)
  .*master~1.*commit 3.* (re)
  .* (re)
  .*master~2.*commit 2.* (re)
  .*master~3.*commit 1.* (re)

And restricts to commits unique to the current branch when it differs
from the default branch, plus one commit of context past the branch
point (default~1..)::

  $ git checkout -qb another
  $ touch another-file && git add another-file && git commit -qam "another commit"
  $ gytr-l
  .*another.*another commit.* (re)
  .*another~1.*master.*merge feature.* (re)
  .*another~1\^2.*feature.*feature commit.* (re)
