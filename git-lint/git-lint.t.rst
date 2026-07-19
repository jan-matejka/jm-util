deterministic commit hashes:

  $ git init -q ./
  $ export GIT_CONFIG_SYSTEM=/dev/null
  $ export GIT_CONFIG_GLOBAL=/dev/null
  $ export GIT_COMMITTER_DATE='1970-01-01T00:00:00'
  $ export GIT_AUTHOR_DATE='1970-01-01T00:00:00'
  $ git config --local user.name "John"
  $ git config --local user.email "john@example.com"
  $ git config --local alias.ci "commit --allow-empty -qm"

subject length limit:

  $ git ci init
  $ git ci foo
  $ git ci bar
  $ git ci "$(printf "x%0.s" {1..80})"
  $ git lint HEAD~1..
  $ git ci "$(printf "x%0.s" {1..81})"
  $ git lint HEAD~1..
  git-lint: title-max-length violation at 0f13e64a355265b9ab6d8c1ff178be38dee93631 by xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx max=80
  [1]
